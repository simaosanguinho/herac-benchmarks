#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/benchmarks.sh

function test_gv_benchmarks {
    TEST_SET=""
    read -p "Test Graalvisor's Java benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $JV_GV_BENCHMARKS"
    fi
    read -p "Test Graalvisor's Python benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $PY_GV_BENCHMARKS"
    fi
    read -p "Test Graalvisor's JavaScript benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $JS_GV_BENCHMARKS"
    fi

    for benchmark in $TEST_SET
    do
        for backend in "svm" "container" "vm"
        do
            for sandbox in "default" "runtime" "process"
            do
                if [ "$sandbox" == "default" ]; then
                    unset SANDBOX
                else
                    export SANDBOX=$sandbox;
                fi
                $(DIR)/benchmark-graalvisor.sh $backend $benchmark test 1 | grep "\"result\""
           done
        done
    done
    unset SANDBOX
}

function test_ow_benchmarks {
    TEST_SET=""
    read -p "Test OpenWhisk's Java benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $JV_CR_BENCHMARKS"
    fi
    read -p "Test OpenWhisk's Python benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $PY_CR_BENCHMARKS"
    fi
    read -p "Test OpenWhisk's JavaScript benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $JS_CR_BENCHMARKS"
    fi

    for benchmark in $TEST_SET
    do
        for backend in "container" "vm"
        do
            $(DIR)/benchmark-cruntime.sh $backend $benchmark test 1
        done
    done
}

function cdf_latency_filehashing {
    export ITERATIONS=5
    $(DIR)/benchmark-cruntime.sh   container cr_java_filehashing test 25
    $(DIR)/benchmark-graalvisor.sh container gv_java_filehashing test 25
    unset ITERATIONS
}

# Memory (fixed HW resources of 1 core and 2GB of memory, measure ops/s/mb)
function efficiency {

    # Graalvisor
    function efficiency_gv {
        declare -A wmultiplier
        wmultiplier_table[gv_java_hw]=1000
        wmultiplier_table[gv_java_filehashing]=1000
        wmultiplier_table[gv_java_httprequest]=1000
        wmultiplier_table[gv_java_videoprocessing]=1
        wmultiplier_table[gv_java_classify]=5
        wmultiplier_table[gv_java_shopcart]=5000
        wmultiplier_table[gv_python_dynamichtml]=5
        wmultiplier_table[gv_python_thumbnail]=5
        wmultiplier_table[gv_python_uploader]=5
        wmultiplier_table[gv_python_compression]=5
        wmultiplier_table[gv_python_videoprocessing]=2

        declare -A bmultiplier
        concurrency_table[gv_java_hw]=8
        concurrency_table[gv_java_filehashing]=8
        concurrency_table[gv_java_httprequest]=8
        concurrency_table[gv_java_videoprocessing]=1
        concurrency_table[gv_java_classify]=1
        concurrency_table[gv_java_shopcart]=8
        concurrency_table[gv_javascript_hw]=8
        concurrency_table[gv_javascript_dynamichtml]=8
        concurrency_table[gv_javascript_uploader]=8
        concurrency_table[gv_javascript_thumbnail]=4
        concurrency_table[gv_python_hw]=8
        concurrency_table[gv_python_dynamichtml]=4
        concurrency_table[gv_python_thumbnail]=2
        concurrency_table[gv_python_uploader]=4
        concurrency_table[gv_python_compression]=4
        concurrency_table[gv_python_videoprocessing]=2
        concurrency_table[gv_python_mst]=8

        function efficiency_gv_java_single {
            for benchmark in $JV_GV_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                unset WMULTIPLIER
            done
        }

        function efficiency_gv_java {
            for benchmark in $JV_GV_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark ${concurrency_table["$benchmark"]}
                unset WMULTIPLIER
            done
        }

        function efficiency_gv_javascript_single {
            for benchmark in $JV_GV_BENCHMARKS;
            do
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
            done
        }

        function efficiency_gv_javascript {
            for benchmark in $JV_GV_BENCHMARKS;
            do
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark ${concurrency_table["$benchmark"]}
            done
        }

        function efficiency_gv_python_single {
            for benchmark in $PY_GV_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                unset WMULTIPLIER
            done
        }

        function efficiency_gv_python {
            for benchmark in $PY_GV_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark ${concurrency_table["$benchmark"]}
                unset WMULTIPLIER
            done
        }

        # All gv benchmarks run on a single core.
        export SANDBOX=isolate; efficiency_gv_java_single
        export SANDBOX=isolate; efficiency_gv_java
        export SANDBOX=process; efficiency_gv_java
        export WARMUP=1; export SANDBOX=context; efficiency_gv_javascript_single
        export WARMUP=1; export SANDBOX=context; efficiency_gv_python_single
        export WARMUP=1; export SANDBOX=context; efficiency_gv_javascript
        export WARMUP=1; export SANDBOX=context; efficiency_gv_python
        export WARMUP=1; export SANDBOX=process; efficiency_gv_javascript
        export WARMUP=1; export SANDBOX=process; efficiency_gv_python
        unset WARMUP
        unset SANDBOX
    }

    # Graalvisor with vm snapshotting
    function efficiency_gv_snapshot {
        snapshots=/tmp/snapshots
        mkdir -p $snapshots

        function efficiency_gv_java {
            declare -A wmultiplier
            wmultiplier_table[gv_java_hw]=2000
            wmultiplier_table[gv_java_shopcart]=1000
            wmultiplier_table[gv_java_videoprocessing]=2
            wmultiplier_table[gv_java_classify]=10

            declare -A mem_table
            declare -A cpu_table
            mem_table[gv_java_hw]=256
            cpu_table[gv_java_hw]=12500 # .125 cores
            mem_table[gv_java_filehashing]=256
            cpu_table[gv_java_filehashing]=12500
            mem_table[gv_java_httprequest]=256
            cpu_table[gv_java_httprequest]=12500
            mem_table[gv_java_shopcart]=256
            cpu_table[gv_java_shopcart]=12500
            mem_table[gv_java_videoprocessing]=1024
            cpu_table[gv_java_videoprocessing]=50000
            mem_table[gv_java_classify]=2048
            cpu_table[gv_java_classify]=50000 # 1 core?

            for benchmark in $JV_GV_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export SNAPSHOT=$snapshots/$benchmark
                sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
                if [ $benchmark = "gv_java_classify" ];
                then
                    # Tensorflow cannot be loaded two! We use test 0 because of that.
                    bash -c "export ITERATIONS=1; $(DIR)/benchmark-graalvisor.sh vm $benchmark test 0"
                else
                    bash -c "export ITERATIONS=1; $(DIR)/benchmark-graalvisor.sh vm $benchmark test 1"
                fi
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                unset WMULTIPLIER
                unset SNAPSHOT
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        function efficiency_gv_javascript {
            declare -A mem_table
            declare -A cpu_table
            mem_table[gv_javascript_hw]=256
            cpu_table[gv_javascript_hw]=12500 # .125 cores
            mem_table[gv_javascript_dynamichtml]=256
            cpu_table[gv_javascript_dynamichtml]=12500
            mem_table[gv_javascript_thumbnail]=512
            cpu_table[gv_javascript_thumbnail]=25000
            mem_table[gv_javascript_uploader]=256
            cpu_table[gv_javascript_uploader]=12500

            for benchmark in $JS_GV_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export SNAPSHOT=$snapshots/$benchmark
                sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
                bash -c "export ITERATIONS=1; $(DIR)/benchmark-graalvisor.sh vm $benchmark test 100"
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                unset SNAPSHOT
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        function efficiency_gv_python {
            declare -A wmultiplier
            wmultiplier_table[gv_python_dynamichtml]=5
            wmultiplier_table[gv_python_uploader]=5
            wmultiplier_table[gv_python_compression]=5
            wmultiplier_table[gv_python_thumbnail]=5
            wmultiplier_table[gv_python_mst]=50
            wmultiplier_table[gv_python_videoprocessing]=2

            declare -A mem_table
            declare -A cpu_table
            mem_table[gv_python_hw]=512
            cpu_table[gv_python_hw]=25000 # .25 cores
            mem_table[gv_python_dynamichtml]=512
            cpu_table[gv_python_dynamichtml]=25000
            mem_table[gv_python_uploader]=512
            cpu_table[gv_python_uploader]=25000
            mem_table[gv_python_compression]=512
            cpu_table[gv_python_compression]=25000
            mem_table[gv_python_thumbnail]=1024
            cpu_table[gv_python_thumbnail]=50000
            mem_table[gv_python_mst]=1024
            cpu_table[gv_python_mst]=50000
            mem_table[gv_python_videoprocessing]=2048
            cpu_table[gv_python_videoprocessing]=100000

            for benchmark in $PY_GV_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export SNAPSHOT=$snapshots/$benchmark
                sudo rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
                bash -c "export ITERATIONS=1; $(DIR)/benchmark-graalvisor.sh vm $benchmark test 100"
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                unset WMULTIPLIER
                unset SNAPSHOT
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        #export SANDBOX="isolate"; efficiency_gv_java; unset SANDBOX
        #export SANDBOX="context"; efficiency_gv_javascript; unset SANDBOX
        export SANDBOX="context"; efficiency_gv_python; unset SANDBOX
    }

    # Openwhisk runtimes
    function efficiency_cr {

        # VM memory and cgroup cpu quota for the following benchmarks.
        export VM_MEM=256
        export CGROUP_CPU_QUOTA=12500 # .125 cores

        $(DIR)/benchmark-cruntime.sh vm cr_java_hw benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_python_hw benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_javascript_hw benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_java_filehashing benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_javascript_dynamichtml benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_python_dynamichtml benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_python_thumbnail benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_javascript_uploader benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_java_httprequest benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_python_uploader benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_python_compression benchmark 1

        # VM memory and cgroup cpu quota for the following benchmarks.
        export VM_MEM=512
        export CGROUP_CPU_QUOTA=25000 # .25 cores

        $(DIR)/benchmark-cruntime.sh vm cr_python_videoprocessing benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_javascript_thumbnail benchmark 1
        $(DIR)/benchmark-cruntime.sh vm cr_python_mst benchmark 1

        export VM_MEM=1024
        export CGROUP_CPU_QUOTA=50000 # .5 cores
        $(DIR)/benchmark-cruntime.sh vm cr_java_videoprocessing benchmark 1
        unset CGROUP_CPU_QUOTA
        unset VM_MEM

        export VM_MEM=2048
        export CGROUP_CPU_QUOTA=100000 # 1 core
        $(DIR)/benchmark-cruntime.sh vm cr_java_classify benchmark 1
        unset CGROUP_CPU_QUOTA
        unset VM_MEM
    }

    export ITERATIONS=1 #3 # Note: by default this should be 5.
    export CGROUP="experiments"
    export PIN_CORE="true"
    # Disabling turbo will make some benchmarks more stable. However, it will make everything much slower.
    export DISABLE_TURBO="false"
    export EXPERIMENT="test-exp"

    #efficiency_gv
    efficiency_gv_snapshot
    #efficiency_cr

    # Clear variables.
    unset ITERATIONS
    unset CGROUP
    unset PIN_CORE
    unset DISABLE_TURBO
    unset EXPERIMENT
}

function startup_latency {

    function startup_latency_gv {
        for mode in svm vm;
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

read -p "Run basic graalvisor tests (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    test_gv_benchmarks
    exit 0
fi

read -p "Run basic openwhisk tests (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    test_ow_benchmarks
    exit 0
fi
read -p "Run cdf latency experiment (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    cdf_latency_filehashing
    exit 0
fi

read -p "Run startup latency experiment (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    startup_latency
    exit 0
fi

read -p "Run efficiency experiment (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    efficiency
    exit 0
fi

