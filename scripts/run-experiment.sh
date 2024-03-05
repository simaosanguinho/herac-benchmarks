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

function measure_benchmark_resources {
    declare -A conc_mem_table
    declare -A conc_cpu_table
    conc_mem_table[1]=2048
    conc_cpu_table[1]=100000
    conc_mem_table[2]=1024
    conc_cpu_table[2]=50000
    conc_mem_table[4]=512
    conc_cpu_table[4]=25000
    conc_mem_table[8]=256
    conc_cpu_table[8]=12500

    for concurrency in 1 2 4 8;
    do
        for benchmark in $GV_BENCHMARKS $CR_BENCHMARKS;
        do
            concurrency_table["$benchmark"]=$concurrency
            mem_table["$benchmark"]=${conc_mem_table["$concurrency"]}
            cpu_table["$benchmark"]=${conc_cpu_table["$concurrency"]}
        done
        efficiency
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
        function efficiency_gv_java {
            for benchmark in $JV_GV_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh container $benchmark benchmark ${concurrency_table["$benchmark"]}
                unset WMULTIPLIER
            done
        }

        function efficiency_gv_javascript {
            for benchmark in $JS_GV_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                if [ "$SANDBOX" = "context-snapshot" ]; then
                    export WARMUP=${concurrency_table["$benchmark"]}
                    rm -f /tmp/apps/*.memsnap  /tmp/apps/*.metasnap # TODO - make this configurable.
                    $(DIR)/benchmark-graalvisor.sh container $benchmark test ${concurrency_table["$benchmark"]}
                fi
                $(DIR)/benchmark-graalvisor.sh container $benchmark benchmark ${concurrency_table["$benchmark"]}
                unset WARMUP
                unset WMULTIPLIER
            done
        }

        function efficiency_gv_python {
            for benchmark in $PY_GV_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                if [ "$SANDBOX" = "context-snapshot" ]; then
                    export WARMUP=${concurrency_table["$benchmark"]}
                    rm -f /tmp/apps/*.memsnap  /tmp/apps/*.metasnap # TODO - make this configurable.
                    $(DIR)/benchmark-graalvisor.sh container $benchmark test ${concurrency_table["$benchmark"]}
                fi
                $(DIR)/benchmark-graalvisor.sh container $benchmark benchmark ${concurrency_table["$benchmark"]}
                unset WARMUP
                unset WMULTIPLIER
            done
        }

        export SANDBOX=isolate; efficiency_gv_java
        export SANDBOX=process; efficiency_gv_java
        export SANDBOX=context-snapshot; efficiency_gv_javascript
        export SANDBOX=context-snapshot; efficiency_gv_python
        export SANDBOX=process; efficiency_gv_javascript
        export SANDBOX=process; efficiency_gv_python
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
                $(DIR)/benchmark-graalvisor.sh container $benchmark benchmark 1
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
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-graalvisor.sh container $benchmark benchmark 1
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
                $(DIR)/benchmark-graalvisor.sh container $benchmark benchmark 1
                unset WMULTIPLIER
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        export SANDBOX=isolate; efficiency_gv_java_single
        export SANDBOX=context; efficiency_gv_javascript_single
        export SANDBOX=context; efficiency_gv_python_single
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
            $(DIR)/benchmark-cruntime.sh container $benchmark benchmark 1
            unset WMULTIPLIER
            unset CGROUP_CPU_QUOTA
            unset VM_MEM
        done
    }

    export ITERATIONS=1 # Note: by default this should be 5.
    export CGROUP="experiments"
    export PIN_CORE="true"
    # Disabling turbo will make some benchmarks more stable. However, it will make everything much slower.
    export DISABLE_TURBO="false"
    export EXPERIMENT="asplos25-spring"
    unset WARMUP
    unset SNAPSHOT

    efficiency_gv
    efficiency_gv_single
    #efficiency_gv_snapshot
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

read -p "Run efficiency experiment (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    efficiency
    exit 0
fi
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

read -p "Run benchmark resources experiment (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    measure_benchmark_resources
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

