#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

function set_cgroup {
    quota=$1
    period=$2
    if [ -d "/sys/fs/cgroup/unified" ]; then
        echo "$period" | sudo tee /sys/fs/cgroup/cpu/$CGROUP/cpu.cfs_period_us &> /dev/null
        echo "$quota"  | sudo tee /sys/fs/cgroup/cpu/$CGROUP/cpu.cfs_quota_us  &> /dev/null
    else
        echo "$quota $period" | sudo tee -a /sys/fs/cgroup/$CGROUP/cpu.max &> /dev/null
    fi
}

GV_BENCHMARKS="$GV_BENCHMARKS gv_java_sleep"
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_sleep"
GV_BENCHMARKS="$GV_BENCHMARKS gv_javascript_sleep"
CR_BENCHMARKS="$CR_BENCHMARKS cr_java_sleep"
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_sleep"
CR_BENCHMARKS="$CR_BENCHMARKS cr_javascript_sleep"
GV_BENCHMARKS="$GV_BENCHMARKS gv_java_hw"                 # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_javascript_hw"           # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_hw"               # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_java_hw"                 # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_javascript_hw"           # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_hw"               # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_java_filehashing"        # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_java_filehashing"        # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_javascript_dynamichtml"  # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_javascript_dynamichtml"  # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_dynamichtml"      # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_dynamichtml"      # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_thumbnail"        # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_thumbnail"        # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_javascript_uploader"     # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_javascript_uploader"     # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_java_httprequest"        # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_java_httprequest"        # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_java_videoprocessing"    # 1024 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_java_videoprocessing"    # 1024 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_uploader"         # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_uploader"         # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_compression"      # 512 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_compression"      # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_videoprocessing"  # 512 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_videoprocessing"  # 512 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_javascript_thumbnail"    # 512 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_javascript_thumbnail"    # 512 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_java_classify"           # 1024 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_java_classify"           # 1024 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_mst"              # 512 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_mst"              # 512 MB


function cdf_latency_filehashing {
    $(DIR)/benchmark-cruntime.sh   vm   cr_java_filehashing test
    $(DIR)/benchmark-graalvisor.sh niuk gv_java_filehashing test
}

function warm_latency {
    export CGROUP="experiments"
    set_cgroup 100000 100000 # 1 core
    for benchmark in $GV_BENCHMARKS; do $(DIR)/benchmark-graalvisor.sh niuk $benchmark test 100 1 2048; done
    for benchmark in $CR_BENCHMARKS; do $(DIR)/benchmark-cruntime.sh   vm   $benchmark test 100 1 2048; done
    unset CGROUP
}

# Memory (fixed HW resources of 1 core and 2GB of memory, measure ops/s/mb)
function efficiency {

    # Graalvisor
    function efficiency_gv {

         function efficiency_gv_java_single {
            export WMULTIPLIER=2000; $(DIR)/benchmark-graalvisor.sh niuk gv_java_hw benchmark 1 1 2048; unset WMULTIPLIER
            export WMULTIPLIER=2000; $(DIR)/benchmark-graalvisor.sh niuk gv_java_filehashing benchmark 1 1 2048; unset WMULTIPLIER
            export WMULTIPLIER=3000; $(DIR)/benchmark-graalvisor.sh niuk gv_java_httprequest benchmark 1 1 2048; unset WMULTIPLIER
            export WMULTIPLIER=2; $(DIR)/benchmark-graalvisor.sh niuk gv_java_videoprocessing benchmark 1 1 2048; unset WMULTIPLIER
            export WMULTIPLIER=10; $(DIR)/benchmark-graalvisor.sh niuk gv_java_classify benchmark 1 1 2048; unset WMULTIPLIER
            export WMULTIPLIER=10000; $(DIR)/benchmark-graalvisor.sh niuk gv_java_shopcart benchmark 1 1 2048; unset WMULTIPLIER
        }

        function efficiency_gv_java {
            export WMULTIPLIER=500; $(DIR)/benchmark-graalvisor.sh niuk gv_java_hw benchmark 8 1 2048; unset WMULTIPLIER
            export WMULTIPLIER=500; $(DIR)/benchmark-graalvisor.sh niuk gv_java_filehashing benchmark 8 1 2048; unset WMULTIPLIER
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_httprequest benchmark 8 1 2048
            export WMULTIPLIER=2; $(DIR)/benchmark-graalvisor.sh niuk gv_java_videoprocessing benchmark 2 1 2048; unset WMULTIPLIER
            # Note: there is a bug in gv, it can't run 2 parallel calls to classify.
            # Since the workload is throughput intensive, having a second one would keep the same throughput so it is fine...
            export WMULTIPLIER=10; $(DIR)/benchmark-graalvisor.sh niuk gv_java_classify benchmark 1 1 2048; unset WMULTIPLIER
            export WMULTIPLIER=5000; $(DIR)/benchmark-graalvisor.sh svm gv_java_shopcart benchmark 8 1 2048; unset WMULTIPLIER
        }

        function efficiency_gv_javascript {
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_hw benchmark 8 1 2048
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_dynamichtml benchmark 8 1 2048
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_uploader benchmark 8 1 2048
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_thumbnail benchmark 4 1 2048
        }

        function efficiency_gv_python {
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_hw benchmark 8 1 2048
            export WMULTIPLIER=5;
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_dynamichtml benchmark 4 1 2048
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_thumbnail benchmark 2 1 2048
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_uploader benchmark 4 1 2048
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_compression benchmark 4 1 2048
            export WMULTIPLIER=2;
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_videoprocessing benchmark 2 1 2048
            export WMULTIPLIER=50;
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_mst benchmark 2 1 2048
            unset WMULTIPLIER
        }

        # All gv benchmarks run on a single core.
        set_cgroup 100000 100000 # 1 core
        for sandbox in "isolate" "runtime" "process"
        do
            export SANDBOX=$sandbox
            efficiency_gv_java_single
            efficiency_gv_java
            unset SANDBOX
        done
        for sandbox in "context" "process"
        do
            export SANDBOX=$sandbox
            # Used only for process sandbox, ignored for context.
            export WARMUP=1
            efficiency_gv_javascript
            efficiency_gv_python
            unset WARMUP
            unset SANDBOX
        done

    }

    # Graalvisor with vm snapshotting
    function efficiency_gv_snapshot {

        function efficiency_gv_java {
            snapshots=/tmp/snapshots/java
            mkdir -p $snapshots

            export SNAPSHOT=$snapshots/hw
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 12500 100000 # .125 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_hw test 1 1 256
            export WMULTIPLIER=2000; $(DIR)/benchmark-graalvisor.sh niuk gv_java_hw benchmark 1 1 256; unset WMULTIPLIER

            export SNAPSHOT=$snapshots/fh
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 12500 100000 # .125 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_filehashing test 1 1 256
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_filehashing benchmark 1 1 256

            export SNAPSHOT=$snapshots/rest
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 12500 100000 # .125 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_httprequest test 1 1 256
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_httprequest benchmark 1 1 256

            export SNAPSHOT=$snapshots/video
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 50000 100000 # .5 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_videoprocessing test 1 1 1024
            export WMULTIPLIER=2; $(DIR)/benchmark-graalvisor.sh niuk gv_java_videoprocessing benchmark 1 1 1024; unset WMULTIPLIER

            export SNAPSHOT=$snapshots/classify
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 50000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_classify test 1 1 2048
            export WMULTIPLIER=10; $(DIR)/benchmark-graalvisor.sh niuk gv_java_classify benchmark 1 1 2048; unset WMULTIPLIER

            export SNAPSHOT=$snapshots/shopcart
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 12500 100000 # .125 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_shopcart test 1 1 256
            export WMULTIPLIER=1000; $(DIR)/benchmark-graalvisor.sh niuk gv_java_shopcart benchmark 1 1 256; unset WMULTIPLIER
            unset SNAPSHOT
        }

        function efficiency_gv_javascript {
            snapshots=/tmp/snapshots/javascript
            mkdir -p $snapshots

            export SNAPSHOT=$snapshots/hw
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 12500 100000 # .125 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_hw test 100 1 256
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_hw benchmark 1 1 256

            export SNAPSHOT=$snapshots/html
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 12500 100000 # .125 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_dynamichtml test 100 1 256
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_dynamichtml benchmark 1 1 256

            export SNAPSHOT=$snapshots/uploader
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 12500 100000 # .125 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_uploader test 100 1 256
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_uploader benchmark 1 1 256

            export SNAPSHOT=$snapshots/uploader
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 25000 100000 # .25 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_thumbnail test 100 1 512
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_thumbnail benchmark 1 1 512
        }

        function efficiency_gv_python {
            snapshots=/tmp/snapshots/python
            mkdir -p $snapshots

            export SNAPSHOT=$snapshots/hw
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 12500 100000 # .125 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_hw test 100 1 256
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_hw benchmark 1 1 256

            export WMULTIPLIER=5;
            export SNAPSHOT=$snapshots/html
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 25000 100000 # .25 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_dynamichtml test $WMULTIPLIER 1 512
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_dynamichtml benchmark 1 1 512

            export SNAPSHOT=$snapshots/thumbnail
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 50000 100000 # .5 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_thumbnail test $WMULTIPLIER 1 1024
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_thumbnail benchmark 1 1 1024

            export SNAPSHOT=$snapshots/uploader
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 25000 100000 # .25 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_uploader test $WMULTIPLIER 1 512
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_uploader benchmark 1 1 512

            export SNAPSHOT=$snapshots/compression
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 25000 100000 # .25 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_compression test $WMULTIPLIER 1 512
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_compression benchmark 1 1 512
            unset WMULTIPLIER

            export WMULTIPLIER=2;
            export SNAPSHOT=$snapshots/video
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 50000 100000 # .5 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_videoprocessing test $WMULTIPLIER 1 1024
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_videoprocessing benchmark 1 1 1024
            unset WMULTIPLIER

            export WMULTIPLIER=50
            export SNAPSHOT=$snapshots/mst
            sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
            set_cgroup 50000 100000 # .5 cores
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_mst test $WMULTIPLIER 1 1024
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_mst benchmark 1 1 1024
            unset WMULTIPLIER
        }

        export SANDBOX="isolate"; efficiency_gv_java; unset SANDBOX
        export SANDBOX="context"; efficiency_gv_javascript; unset SANDBOX
        export SANDBOX="context"; efficiency_gv_python; unset SANDBOX
    }

    # Openwhisk runtimes
    function efficiency_cr {
        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_java_hw benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_python_hw benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_javascript_hw benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_java_filehashing benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_javascript_dynamichtml benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_python_dynamichtml benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_python_thumbnail benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_javascript_uploader benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_java_httprequest benchmark 1 1 256

        set_cgroup 50000 100000 # .5 cores
        $(DIR)/benchmark-cruntime.sh vm cr_java_videoprocessing benchmark 1 1 1024

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_python_uploader benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh vm cr_python_compression benchmark 1 1 256

        set_cgroup 25000 100000 # .25 cores
        $(DIR)/benchmark-cruntime.sh vm cr_python_videoprocessing benchmark 1 1 512

        set_cgroup 25000 100000 # .25 cores
        $(DIR)/benchmark-cruntime.sh vm cr_javascript_thumbnail benchmark 1 1 512

        set_cgroup 50000 100000 # 1 core
        $(DIR)/benchmark-cruntime.sh vm cr_java_classify benchmark 1 1 2048

        set_cgroup 25000 100000 # .25 cores
        $(DIR)/benchmark-cruntime.sh vm cr_python_mst benchmark 1 1 512
    }

    # Photons runtimes
    function efficiency_ph {
        set_cgroup 100000 100000 # 1 core
        $(DIR)/benchmark-cruntime.sh vm ph_java_hw benchmark 8 1 2048
        $(DIR)/benchmark-cruntime.sh vm ph_java_filehashing benchmark 8 1 2048
        $(DIR)/benchmark-cruntime.sh vm ph_java_httprequest benchmark 8 1 2048
        export WMULTIPLIER=2; $(DIR)/benchmark-cruntime.sh vm ph_java_videoprocessing benchmark 2 1 2048; unset WMULTIPLIER
        export WMULTIPLIER=5;$(DIR)/benchmark-cruntime.sh vm ph_java_classify benchmark 1 1 2048; unset WMULTIPLIER
    }

    export CGROUP="experiments"

    # Create cgroup.
    sudo mkdir /sys/fs/cgroup/$CGROUP

    efficiency_gv

    efficiency_gv_snapshot

    efficiency_cr

    efficiency_ph

    # To remove cgroup.
    sudo rmdir /sys/fs/cgroup/$CGROUP

    # Clear variable.
    unset CGROUP
}

function startup_latency {

    function startup_latency_gv {
        for mode in svm niuk;
        do
            for i in $(seq 1 10);
            do
                $(DIR)/benchmark-graalvisor.sh $mode gv_java_hw test 1
                cat /tmp/test-proxy/lambda.log | grep "Polyglot Lambda boot time"
            done
        done
    }

    function startup_latency_cr {
        if [[ -z "${FIRECRACKER_CONTAINERD_HOME}" ]]; then
            echo "FIRECRACKER_CONTAINERD_HOME is not defined."
            echo "Run export FIRECRACKER_CONTAINERD_HOME=/home/$USER/git/firecracker-containerd ?"
            echo "Exiting..."
            exit 1
        fi

        JS_IMG="docker.io/rfbpb/action-nodejs-v14:latest"
        PY_IMG="docker.io/rfbpb/action-python-v3.7:latest"
        JV_IMG="docker.io/rfbpb/java8action:latest"

        # JS, PY, JV on custom runtime.
        for img in $JS_IMG $PY_IMG $JV_IMG;
        do
            $FIRECRACKER_CONTAINERD_HOME/demo/firecracker-ctr.sh run --snapshotter devmapper --runtime aws.firecracker --tty --net-host $img vm1 &
            wait_port $ip 8080
            $FIRECRACKER_CONTAINERD_HOME/demo/firecracker-ctr.sh task kill -a vm1
            wait
            for i in $(seq 1 10);
            do
                echo "Starting $img at $(($(date +%s%N)/1000000)) ms"
                $FIRECRACKER_CONTAINERD_HOME/demo/firecracker-ctr.sh task start vm1 &
                wait_port $ip 8080
                $FIRECRACKER_CONTAINERD_HOME/demo/firecracker-ctr.sh task kill -a vm1
                wait
            done
            $FIRECRACKER_CONTAINERD_HOME/demo/firecracker-ctr.sh container del vm1
        done

        # JS vanilla, extract from virt-bench
        # PY vanilla, extract from virt-bench
        # JV vanilla, extract from virt-bench
    }

    startup_latency_gv
    startup_latency_cr
}

#cdf_latency_filehashing
#warm_latency
efficiency
#startup_latency

