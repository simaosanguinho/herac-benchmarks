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
        for backend in "svm" #"container" "vm"
        do
            echo "$(tput bold)Benchmark: $benchmark in $backend $(tput sgr0)"
            export SANDBOX="default"; $(DIR)/benchmark-graalvisor.sh $backend $benchmark test 1 | grep "Req output:"
            export SANDBOX="process"; $(DIR)/benchmark-graalvisor.sh $backend $benchmark test 1 | grep "Req output:"
            if [[ $benchmark == *"gv_java_classify"* || $benchmark == *"videoprocessing"* || $benchmark == *"javascript_thumbnail"* ]]; then
                echo "Skipping $benchmark (not supported)"
                continue
            fi
            export ITERATIONS=2 # One iteration for the checkpoint, another for the restore.
            export WARMUP=1
            export SANDBOX=snapshot; $(DIR)/benchmark-graalvisor.sh $backend $benchmark test 0 | grep "Req output:"
            unset WARMUP
            unset ITERATIONS
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

function cold_start_latency {
    export EXPERIMENT="coldstart"
    cr_benchmark=cr_python_hw
    gv_benchmark=gv_python_hw

    function context_snapshot {
        export WARMUP=1
        export SANDBOX=context-snapshot
        rm -rf $ADIR/*.memsnap $ADIR/*.metasnap
        $(DIR)/benchmark-graalvisor.sh svm $gv_benchmark test 0
        unset SANDBOX
        unset WARMUP
    }

    function process_snapshot {
        export SNAPSHOT=$SDIR/$gv_benchmark
        rm -rf $SNAPSHOT
        $(DIR)/benchmark-graalvisor.sh svm $gv_benchmark test 1
        unset SNAPSHOT
    }

    function vm_snapshot {
        export SNAPSHOT=$SDIR/$gv_benchmark
        rm -rf $SNAPSHOT.{disk,mem,snap}
        $(DIR)/benchmark-graalvisor.sh vm $gv_benchmark test 1
        unset SNAPSHOT
    }

    # TODO - use cgroups?
    $(DIR)/benchmark-cruntime.sh   container $cr_benchmark test 1
    $(DIR)/benchmark-cruntime.sh   vm        $cr_benchmark test 1
    $(DIR)/benchmark-graalvisor.sh svm       $gv_benchmark test 1
    $(DIR)/benchmark-graalvisor.sh container $gv_benchmark test 1
    $(DIR)/benchmark-graalvisor.sh vm        $gv_benchmark test 1
    export ITERATIONS=2 # Note: one iteration to dump, another to restore.
    context_snapshot
    process_snapshot
    vm_snapshot
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
                    rm -f $ADIR/*.memsnap  $ADIR/*.metasnap
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
                    rm -f $ADIR/*.memsnap $ADIR/*.metasnap
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

read -p "Run cold start latency experiment (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    cold_start_latency
    exit 0
fi
