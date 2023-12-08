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

    declare -A wmultiplier_table
    wmultiplier_table[gv_java_hw]=2000
    wmultiplier_table[cr_java_hw]=2000
    wmultiplier_table[gv_java_filehashing]=1000
    wmultiplier_table[cr_java_filehashing]=1000
    wmultiplier_table[gv_java_classify]=10
    wmultiplier_table[cr_java_classify]=10
    wmultiplier_table[gv_java_httprequest]=1000
    wmultiplier_table[cr_java_httprequest]=1000
    wmultiplier_table[gv_java_videoprocessing]=2
    wmultiplier_table[cr_java_videoprocessing]=2

    wmultiplier_table[gv_python_hw]=5
    wmultiplier_table[cr_python_hw]=5
    wmultiplier_table[gv_python_mst]=5
    wmultiplier_table[cr_python_mst]=5
    wmultiplier_table[gv_python_bfs]=5
    wmultiplier_table[cr_python_bfs]=5
    wmultiplier_table[gv_python_pagerank]=5
    wmultiplier_table[cr_python_pagerank]=5
    wmultiplier_table[gv_python_dna]=2
    wmultiplier_table[cr_python_dna]=2
    wmultiplier_table[gv_python_classify]=1
    wmultiplier_table[cr_python_classify]=1
    wmultiplier_table[gv_python_dynamichtml]=5
    wmultiplier_table[cr_python_dynamichtml]=5
    wmultiplier_table[gv_python_compression]=5
    wmultiplier_table[cr_python_compression]=5
    wmultiplier_table[gv_python_thumbnail]=5
    wmultiplier_table[cr_python_thumbnail]=5
    wmultiplier_table[gv_python_videoprocessing]=1
    wmultiplier_table[cr_python_videoprocessing]=1
    wmultiplier_table[gv_python_uploader]=5
    wmultiplier_table[cr_python_uploader]=5

    wmultiplier_table[gv_javascript_hw]=256
    wmultiplier_table[cr_javascript_hw]=256
    wmultiplier_table[gv_javascript_dynamichtml]=256
    wmultiplier_table[cr_javascript_dynamichtml]=256
    wmultiplier_table[gv_javascript_thumbnail]=256
    wmultiplier_table[cr_javascript_thumbnail]=256
    wmultiplier_table[gv_javascript_uploader]=256
    wmultiplier_table[cr_javascript_uploader]=256

    declare -A concurrency_table
    concurrency_table[gv_java_hw]=8
    concurrency_table[gv_java_filehashing]=8
    concurrency_table[gv_java_classify]=1
    concurrency_table[gv_java_httprequest]=8
    concurrency_table[gv_java_videoprocessing]=1

    concurrency_table[gv_python_hw]=8
    concurrency_table[gv_python_mst]=4
    concurrency_table[gv_python_bfs]=4
    concurrency_table[gv_python_pagerank]=4
    concurrency_table[gv_python_dna]=2
    concurrency_table[gv_python_classify]=1
    concurrency_table[gv_python_dynamichtml]=4
    concurrency_table[gv_python_compression]=4
    concurrency_table[gv_python_thumbnail]=2
    concurrency_table[gv_python_videoprocessing]=2
    concurrency_table[gv_python_uploader]=4

    concurrency_table[gv_javascript_hw]=8
    concurrency_table[gv_javascript_dynamichtml]=8
    concurrency_table[gv_javascript_thumbnail]=4
    concurrency_table[gv_javascript_uploader]=8

    declare -A mem_table
    declare -A cpu_table
    mem_table[gv_java_hw]=256
    mem_table[cr_java_hw]=256
    cpu_table[gv_java_hw]=12500
    cpu_table[cr_java_hw]=12500
    mem_table[gv_java_filehashing]=256
    mem_table[cr_java_filehashing]=256
    cpu_table[gv_java_filehashing]=12500
    cpu_table[cr_java_filehashing]=12500
    mem_table[gv_java_classify]=2048
    mem_table[cr_java_classify]=2048
    cpu_table[gv_java_classify]=100000
    cpu_table[cr_java_classify]=100000
    mem_table[gv_java_httprequest]=256
    mem_table[cr_java_httprequest]=256
    cpu_table[gv_java_httprequest]=12500
    cpu_table[cr_java_httprequest]=12500
    mem_table[gv_java_videoprocessing]=2048
    mem_table[cr_java_videoprocessing]=2048
    cpu_table[gv_java_videoprocessing]=100000
    cpu_table[cr_java_videoprocessing]=100000

    mem_table[gv_python_hw]=512
    mem_table[cr_python_hw]=256 # TODO - diff
    cpu_table[gv_python_hw]=25000
    cpu_table[cr_python_hw]=12500 # TODO - diff
    mem_table[gv_python_mst]=1024
    mem_table[cr_python_mst]=512 # TODO - diff
    cpu_table[gv_python_mst]=50000
    cpu_table[cr_python_mst]=25000 # TODO - diff
    mem_table[gv_python_bfs]=1024
    mem_table[cr_python_bfs]=512 # TODO - diff
    cpu_table[gv_python_bfs]=50000
    cpu_table[cr_python_bfs]=25000 # TODO - diff
    mem_table[gv_python_pagerank]=1024
    mem_table[cr_python_pagerank]=512 # TODO - diff
    cpu_table[gv_python_pagerank]=50000
    cpu_table[cr_python_pagerank]=25000 # TODO - diff
    mem_table[gv_python_dna]=1024
    mem_table[cr_python_dna]=1024
    cpu_table[gv_python_dna]=50000
    cpu_table[cr_python_dna]=50000
    mem_table[gv_python_classify]=2048
    mem_table[cr_python_classify]=2048
    cpu_table[gv_python_classify]=100000
    cpu_table[cr_python_classify]=100000
    mem_table[gv_python_dynamichtml]=512
    mem_table[cr_python_dynamichtml]=256 # TODO - diff
    cpu_table[gv_python_dynamichtml]=25000
    cpu_table[cr_python_dynamichtml]=12500 # TODO - diff
    mem_table[gv_python_compression]=512
    mem_table[cr_python_compression]=256 # TODO - diff
    cpu_table[gv_python_compression]=25000
    cpu_table[cr_python_compression]=12500 # TODO - diff
    mem_table[gv_python_thumbnail]=1024
    mem_table[cr_python_thumbnail]=256 # TODO - diff
    cpu_table[gv_python_thumbnail]=50000
    cpu_table[cr_python_thumbnail]=12500 # TODO - diff
    mem_table[gv_python_videoprocessing]=2048
    mem_table[cr_python_videoprocessing]=2048
    cpu_table[gv_python_videoprocessing]=100000
    cpu_table[cr_python_videoprocessing]=100000
    mem_table[gv_python_uploader]=512
    mem_table[cr_python_uploader]=256 # TODO - diff
    cpu_table[gv_python_uploader]=25000
    cpu_table[cr_python_uploader]=12500 # TODO - diff

    mem_table[gv_javascript_hw]=256
    mem_table[cr_javascript_hw]=256
    cpu_table[gv_javascript_hw]=12500
    cpu_table[cr_javascript_hw]=12500
    mem_table[gv_javascript_dynamichtml]=256
    mem_table[cr_javascript_dynamichtml]=256
    cpu_table[gv_javascript_dynamichtml]=12500
    cpu_table[cr_javascript_dynamichtml]=12500
    mem_table[gv_javascript_thumbnail]=512
    mem_table[cr_javascript_thumbnail]=512
    cpu_table[gv_javascript_thumbnail]=25000
    cpu_table[cr_javascript_thumbnail]=25000
    mem_table[gv_javascript_uploader]=256
    mem_table[cr_javascript_uploader]=256
    cpu_table[gv_javascript_uploader]=12500
    cpu_table[cr_javascript_uploader]=12500


    # Graalvisor
    function efficiency_gv {
        function efficiency_gv_java {
            for benchmark in $JV_GV_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark ${concurrency_table["$benchmark"]}
                unset WMULTIPLIER
            done
        }

        function efficiency_gv_javascript {
            for benchmark in $JS_GV_BENCHMARKS;
            do
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark ${concurrency_table["$benchmark"]}
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

        export SANDBOX=isolate; efficiency_gv_java
        export SANDBOX=process; efficiency_gv_java
        export WARMUP=1; export SANDBOX=context; efficiency_gv_javascript
        export WARMUP=1; export SANDBOX=context; efficiency_gv_python
        export WARMUP=1; export SANDBOX=process; efficiency_gv_javascript
        export WARMUP=1; export SANDBOX=process; efficiency_gv_python
        unset WARMUP
        unset SANDBOX
    }

    # Graalvisor with a single invocation at a time.
    function efficiency_gv_single {
        function efficiency_gv_java_single {
            for benchmark in $JV_GV_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                unset WMULTIPLIER
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        function efficiency_gv_javascript_single {
            for benchmark in $JS_GV_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        function efficiency_gv_python_single {
            for benchmark in $PY_GV_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                unset WMULTIPLIER
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        export SANDBOX=isolate; efficiency_gv_java_single
        export WARMUP=1; export SANDBOX=context; efficiency_gv_javascript_single
        export WARMUP=1; export SANDBOX=context; efficiency_gv_python_single
        unset WARMUP
        unset SANDBOX
    }

    # Graalvisor with vm snapshotting
    function efficiency_gv_snapshot {
        snapshots=$HOME/tmp/snapshots
        mkdir -p $snapshots

        function efficiency_gv_java {
            for benchmark in $JV_GV_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export SNAPSHOT=$snapshots/$benchmark
                if [ $benchmark = "gv_java_classify" ];
                then
                    # Tensorflow cannot be loaded two! We use test 0 because of that.
                    bash -c "export ITERATIONS=1; $(DIR)/benchmark-graalvisor.sh vm $benchmark test 0"
                else
                    bash -c "export ITERATIONS=1; $(DIR)/benchmark-graalvisor.sh vm $benchmark test 1"
                fi
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                rm $SNAPSHOT.{disk,mem,snap}  &> /dev/null
                unset WMULTIPLIER
                unset SNAPSHOT
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        function efficiency_gv_javascript {
            for benchmark in $JS_GV_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export SNAPSHOT=$snapshots/$benchmark
                bash -c "export ITERATIONS=1; $(DIR)/benchmark-graalvisor.sh vm $benchmark test 100"
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
                unset SNAPSHOT
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        function efficiency_gv_python {
            for benchmark in $PY_GV_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export SNAPSHOT=$snapshots/$benchmark
                bash -c "export ITERATIONS=1; $(DIR)/benchmark-graalvisor.sh vm $benchmark test 100"
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh vm $benchmark benchmark 1
                rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
                unset WMULTIPLIER
                unset SNAPSHOT
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        export SANDBOX="isolate"; efficiency_gv_java; unset SANDBOX
        export SANDBOX="context"; efficiency_gv_javascript; unset SANDBOX
        export SANDBOX="context"; efficiency_gv_python; unset SANDBOX
    }

    # Openwhisk runtimes
    function efficiency_cr {
        for benchmark in $CR_BENCHMARKS;
        do
            export VM_MEM=${mem_table["$benchmark"]}
            export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
            export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
            $(DIR)/benchmark-cruntime.sh vm $benchmark benchmark 1
            unset WMULTIPLIER
            unset CGROUP_CPU_QUOTA
            unset VM_MEM
        done
    }

    export ITERATIONS=3 # Note: by default this should be 5.
    export CGROUP="experiments"
    export PIN_CORE="true"
    # Disabling turbo will make some benchmarks more stable. However, it will make everything much slower.
    export DISABLE_TURBO="false"
    export EXPERIMENT="test-exp"

    efficiency_gv
    efficiency_gv_single
    efficiency_gv_snapshot
    efficiency_cr

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

