#!/bin/bash

function DIR {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

function cidr_to_netmask() {
    value=$(( 0xffffffff ^ ((1 << (32 - $1)) - 1) ))
    echo "$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"
}

function next_ip(){
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $1 | sed -e 's/\./ /g'`)
    NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + 1 ))`)
    NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo $NEXT_IP_HEX | sed -r 's/(..)/0x\1 /g'`)
    echo "$NEXT_IP"
}

function wait_port {
    host=$1
    port=$2
    while ! nc -z $host $port; do echo "Waiting for $host:$port"; sleep 0.1; done
}

# Preparing global paths.
if [[ -z "${ARGO_HOME}" ]]; then
        echo "ARGO_HOME is not defined. Existing..."
        exit 1
else
    MANAGER_HOME=$ARGO_HOME/lambda-manager
    CRUNTIME_HOME=$ARGO_HOME/lambda-manager/src/scripts/cruntime
    NIUK_HOME=$ARGO_HOME/niuk
    GRAALVISOR_HOME=$ARGO_HOME/graalvisor
    RES_HOME=$ARGO_HOME/resources
fi
if [[ -z "${JAVA_HOME}" ]]; then
        echo "JAVA_HOME is not defined. Existing..."
        exit 1
fi

BENCHMARKS_HOME=$(DIR)/..
tmpdir=/tmp/test-proxy
mkdir $tmpdir &> /dev/null

# TODO - make this a function?
# Network setup for the test. Gateway is the ip of the host. The guest will have the next ip.
gateway=$(ip route get 8.8.8.8 | grep -oP  'src \K\S+')
smask=$(ip r | grep $gateway | awk '{print $1}' | awk -F / '{print $2}')
mask=$(cidr_to_netmask $smask)
ip=$(next_ip $gateway)

# Default memory and cpu count.
MEM=2048
CPU=1

function pretime {
	ts=$(date +%s%N)
}

function postime {
	tt=$((($(date +%s%N) - $ts)/1000))
	printf "\nTime taken: $tt us\n"
}

function log_rss {
	PID=$1
	OFILE=$2
	sudo rm $OFILE &> /dev/null
        while sudo kill -0 $PID &> /dev/null; do
                ps -q $PID -o rss= >> $OFILE
                sleep .5
        done
}

function start_niuk {
	cp $GRAALVISOR_HOME/build/native-image/polyglot-proxy.img $tmpdir
	cd $tmpdir
	proxy_args="lambda_timestamp=$(date +%s%N | cut -b1-13) lambda_port=8080 LD_LIBRARY_PATH=/lib:/lib64:/apps:/usr/local/lib JAVA_HOME=/jvm"
	sudo bash $MANAGER_HOME/src/scripts/create_taps.sh testtap $ip
	sudo bash $NIUK_HOME/run_niuk.sh \
		--vmm firecracker \
		--disk $tmpdir/polyglot-proxy.img \
		--kernel $RES_HOME/hello-vmlinux.bin \
		--memory $MEM \
		--cpu $CPU \
		--ip $ip \
		--gateway $gateway \
		--mask $mask \
		--tap testtap \
		--console \
		$proxy_args 
}

function start_container {
	docker run --rm --name=gcontainer --network host -e lambda_timestamp="$(date +%s%N | cut -b1-13)" -e lambda_port="8080" -e JAVA_HOME="/jvm" graalvisor:latest
}

function start_svm {
	cp $GRAALVISOR_HOME/build/native-image/polyglot-proxy $tmpdir/app
	cd $tmpdir
	export lambda_timestamp="$(date +%s%N | cut -b1-13)"
	export lambda_port="8080"
	./app
}

function stop_niuk {
	sudo kill $PID
	sudo bash $MANAGER_HOME/src/scripts/remove_taps.sh testtap
}

function stop_container {
	docker kill gcontainer
}

function stop_baremetal {
	sudo kill $PID
}

