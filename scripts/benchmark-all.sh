#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

function set_cgroup {
    quota=$1
    period=$2
    if [ -d "/sys/fs/cgroup/unified" ]; then
        echo "$period" | sudo tee /sys/fs/cgroup/cpu/$CGROUP/cpu.cfs_period_us
        echo "$quota"  | sudo tee /sys/fs/cgroup/cpu/$CGROUP/cpu.cfs_quota_us
    else
        echo "$quota $period" | sudo tee -a /sys/fs/cgroup/$CGROUP/cpu.max
    fi
}

GV_BENCHMARKS="$GV_BENCHMARKS gv_java_hw"                 # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_javascript_hw"           # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_hw"               # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_java_hw"                 # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_javascript_hw"           # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_hw"               # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_java_sleep"
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_sleep"
GV_BENCHMARKS="$GV_BENCHMARKS gv_javascript_sleep"
CR_BENCHMARKS="$CR_BENCHMARKS cr_java_sleep"
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_sleep"
CR_BENCHMARKS="$CR_BENCHMARKS cr_javascript_sleep"
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
CR_BENCHMARKS="$CR_BENCHMARKS cr_java_videoprocessing"    # 1024 MB, note reduce benchmark to 10*workload
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_uploader"         # 256 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_uploader"         # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_compression"      # 512 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_compression"      # 256 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_videoprocessing"  # 512 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_videoprocessing"  # 512 MB, note reduce benchmark to 10*workload
GV_BENCHMARKS="$GV_BENCHMARKS gv_javascript_thumbnail"    # 512 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_javascript_thumbnail"    # 512 MB
GV_BENCHMARKS="$GV_BENCHMARKS gv_java_classify"           # 1024 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_java_classify"           # 1024 MB, note reduce benchmark to 50*workload
GV_BENCHMARKS="$GV_BENCHMARKS gv_python_mst"              # 512 MB
CR_BENCHMARKS="$CR_BENCHMARKS cr_python_mst"              # 512 MB


function cdf_latency_filehashing {
    $(DIR)/benchmark-cruntime.sh        cr_java_filehashing test
    $(DIR)/benchmark-graalvisor.sh niuk gv_java_filehashing test
}

function warm_latency {
    export CGROUP="experiments"
    set_cgroup 100000 100000 # 1 core
    for benchmark in $GV_BENCHMARKS; do $(DIR)/benchmark-graalvisor.sh niuk $benchmark test 100 1 2048; done
    for benchmark in $CR_BENCHMARKS; do $(DIR)/benchmark-cruntime.sh        $benchmark test 100 1 2048; done
    unset CGROUP
}

# Memory (fixed HW resources of 1 core and 2GB of memory, measure ops/s/mb)
function memory {

    # Run graalvisor with 1 to 8 concurrent requests -> measure tput and RSS
    function memory_gv {

        function memory_gv_java {
            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_hw benchmark 8 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_filehashing benchmark 8 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_httprequest benchmark 8 1 2048

            # These benchmarks take a long time so we are setting the workload to 10*concurrency.
            export WMULTIPLIER=5

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_videoprocessing benchmark 2 1 2048

            set_cgroup 100000 100000 # 1 core
            # Note: there is a bug in gv, it can't run 2 parallel calls to classify.
            # Since the workload is throughput intensive, having a second one would keep the same throughput so it is fine...
            $(DIR)/benchmark-graalvisor.sh niuk gv_java_classify benchmark 1 1 2048

            unset WMULTIPLIER
        }

    function memory_gv_javascript {
            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_hw benchmark 8 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_dynamichtml benchmark 8 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_uploader benchmark 8 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_javascript_thumbnail benchmark 4 1 2048
        }

        function memory_gv_python {
            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_hw benchmark 8 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_dynamichtml benchmark 8 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_thumbnail benchmark 8 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_uploader benchmark 8 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_compression benchmark 4 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_videoprocessing benchmark 4 1 2048

            set_cgroup 100000 100000 # 1 core
            $(DIR)/benchmark-graalvisor.sh niuk gv_python_mst benchmark 4 1 2048
        }

        for sandbox in "isolate" "runtime" "process"
        do
            export SANDBOX=$sandbox
            memory_gv_java
            unset SANDBOX
        done
        memory_gv_javascript
        memory_gv_python
    }

    # Run custom runtime with 1 to 8 concurrent requests
    function memory_cr {
        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_java_hw benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_python_hw benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_javascript_hw benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_java_filehashing benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_javascript_dynamichtml benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_python_dynamichtml benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_python_thumbnail benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_javascript_uploader benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_java_httprequest benchmark 1 1 256

        set_cgroup 50000 100000 # .5 cores
        $(DIR)/benchmark-cruntime.sh cr_java_videoprocessing benchmark 1 1 1024

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_python_uploader benchmark 1 1 256

        set_cgroup 12500 100000 # .125 cores
        $(DIR)/benchmark-cruntime.sh cr_python_compression benchmark 1 1 256

        set_cgroup 25000 100000 # .25 cores
        $(DIR)/benchmark-cruntime.sh cr_python_videoprocessing benchmark 1 1 512

        set_cgroup 25000 100000 # .25 cores
        $(DIR)/benchmark-cruntime.sh cr_javascript_thumbnail benchmark 1 1 512

        set_cgroup 50000 100000 # 1 core
        $(DIR)/benchmark-cruntime.sh cr_java_classify benchmark 1 1 1024

        set_cgroup 25000 100000 # .25 cores
        $(DIR)/benchmark-cruntime.sh cr_python_mst benchmark 1 1 512
    }

    export CGROUP="experiments"

    # Create cgroup.
    sudo mkdir /sys/fs/cgroup/$CGROUP

    memory_gv

    memory_cr

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
memory
#startup_latency

