#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/benchmarks.sh

function test_hy_benchmarks {
    TEST_SET=""
    read -p "Test Hydra's Java benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $JV_HY_BENCHMARKS"
    fi
    read -p "Test Hydra's Python benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $PY_HY_BENCHMARKS"
    fi
    read -p "Test Hydra's JavaScript benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $JS_HY_BENCHMARKS"
    fi

    for benchmark in $TEST_SET
    do
        for backend in "svm" #"container" "vm"
        do
            echo "$(tput bold)Benchmark: $benchmark in $backend $(tput sgr0)"
            export SANDBOX="default"; $(DIR)/benchmark-hydra.sh $backend $benchmark test 1 | grep "Req output:"
            export SANDBOX="process"; $(DIR)/benchmark-hydra.sh $backend $benchmark test 1 | grep "Req output:"
            if [[ $benchmark == *"hy_java_classify"* || $benchmark == *"videoprocessing"* || $benchmark == *"javascript_thumbnail"* ]]; then
                echo "Skipping $benchmark (not supported)"
                continue
            fi
            export ITERATIONS=2 # One iteration for the checkpoint, another for the restore.
            export WARMUP=1
            export SANDBOX=snapshot; $(DIR)/benchmark-hydra.sh $backend $benchmark test 0 | grep "Req output:"
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

function test_kn_benchmarks {
    TEST_SET=""
    read -p "Test Knative's Java benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $JV_KN_BENCHMARKS"
    fi
    read -p "Test Knative's Python benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $PY_KN_BENCHMARKS"
    fi
    read -p "Test Knative's JavaScript benchmarks (y or Y, everything else as no)? " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TEST_SET="$TEST_SET $JS_KN_BENCHMARKS"
    fi

    for benchmark in $TEST_SET
    do
        $(DIR)/benchmark-knative.sh $benchmark test 1
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
        for benchmark in $HY_BENCHMARKS $CR_BENCHMARKS $KN_BENCHMARKS;
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
    hy_benchmark=hy_python_hw
    kn_benchmark=kn_python_hw

    function context_snapshot {
        export WARMUP=1
        export SANDBOX=snapshot
        rm -rf $ADIR/*.memsnap $ADIR/*.metasnap
        $(DIR)/benchmark-hydra.sh svm $hy_benchmark test 0
        unset SANDBOX
        unset WARMUP
    }

    function process_snapshot {
        export SNAPSHOT=$SDIR/$hy_benchmark
        rm -rf $SNAPSHOT
        $(DIR)/benchmark-hydra.sh svm $hy_benchmark test 1
        unset SNAPSHOT
    }

    function vm_snapshot {
        export SNAPSHOT=$SDIR/$hy_benchmark
        rm -rf $SNAPSHOT.{disk,mem,snap}
        $(DIR)/benchmark-hydra.sh vm $hy_benchmark test 1
        unset SNAPSHOT
    }

    # TODO - use cgroups?
    $(DIR)/benchmark-cruntime.sh   container $cr_benchmark test 1
    $(DIR)/benchmark-cruntime.sh   vm        $cr_benchmark test 1
    $(DIR)/benchmark-hydra.sh svm       $hy_benchmark test 1
    $(DIR)/benchmark-hydra.sh container $hy_benchmark test 1
    $(DIR)/benchmark-hydra.sh vm        $hy_benchmark test 1
    $(DIR)/benchmark-knative.sh              $kn_benchmark test 1
    export ITERATIONS=2 # Note: one iteration to dump, another to restore.
    context_snapshot
    process_snapshot
    vm_snapshot
    unset ITERATIONS
}

# Memory (fixed HW resources of 1 core and 2GB of memory, measure ops/s/mb)
function efficiency {

    # Hydra
    function efficiency_hy {
        function efficiency_hy_java {
            for benchmark in $JV_HY_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-hydra.sh container $benchmark benchmark ${concurrency_table["$benchmark"]}
                unset WMULTIPLIER
            done
        }

        function efficiency_hy_javascript {
            for benchmark in $JS_HY_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                if [ "$SANDBOX" = "snapshot" ]; then
                    export WARMUP=${concurrency_table["$benchmark"]}
                    rm -f $ADIR/*.memsnap  $ADIR/*.metasnap
                    $(DIR)/benchmark-hydra.sh container $benchmark test ${concurrency_table["$benchmark"]}
                fi
                export KEEP_SNAPSHOTS=true
                $(DIR)/benchmark-hydra.sh container $benchmark benchmark ${concurrency_table["$benchmark"]}
                unset KEEP_SNAPSHOTS
                unset WARMUP
                unset WMULTIPLIER
            done
        }

        function efficiency_hy_python {
            for benchmark in $PY_HY_BENCHMARKS;
            do
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                if [ "$SANDBOX" = "snapshot" ]; then
                    export WARMUP=${concurrency_table["$benchmark"]}
                    rm -f $ADIR/*.memsnap $ADIR/*.metasnap
                    $(DIR)/benchmark-hydra.sh container $benchmark test ${concurrency_table["$benchmark"]}
                fi
                export KEEP_SNAPSHOTS=true
                $(DIR)/benchmark-hydra.sh container $benchmark benchmark ${concurrency_table["$benchmark"]}
                unset KEEP_SNAPSHOTS
                unset WARMUP
                unset WMULTIPLIER
            done
        }

        export SANDBOX=isolate; efficiency_hy_java
        export SANDBOX=process; efficiency_hy_java
        export SANDBOX=snapshot; efficiency_hy_javascript
        export SANDBOX=snapshot; efficiency_hy_python
        export SANDBOX=process; efficiency_hy_javascript
        export SANDBOX=process; efficiency_hy_python
        unset WARMUP
        unset SANDBOX
    }

    # Hydra with a single invocation at a time.
    function efficiency_hy_single {
        function efficiency_hy_java_single {
            for benchmark in $JV_HY_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-hydra.sh container $benchmark benchmark 1
                unset WMULTIPLIER
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        function efficiency_hy_javascript_single {
            for benchmark in $JS_HY_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-hydra.sh container $benchmark benchmark 1
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        function efficiency_hy_python_single {
            for benchmark in $PY_HY_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-hydra.sh container $benchmark benchmark 1
                unset WMULTIPLIER
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        export SANDBOX=isolate; efficiency_hy_java_single
        export SANDBOX=context; efficiency_hy_javascript_single
        export SANDBOX=context; efficiency_hy_python_single
        unset WARMUP
        unset SANDBOX
    }

    # Hydra with vm snapshotting
    function efficiency_hy_snapshot {
        snapshots=$HOME/tmp/snapshots
        mkdir -p $snapshots

        function efficiency_hy_java {
            for benchmark in $JV_HY_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export SNAPSHOT=$snapshots/$benchmark
                if [ $benchmark = "hy_java_classify" ];
                then
                    # Tensorflow cannot be loaded two! We use test 0 because of that.
                    bash -c "export ITERATIONS=1; $(DIR)/benchmark-hydra.sh vm $benchmark test 0"
                else
                    bash -c "export ITERATIONS=1; $(DIR)/benchmark-hydra.sh vm $benchmark test 1"
                fi
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-hydra.sh vm $benchmark benchmark 1
                rm $SNAPSHOT.{disk,mem,snap}  &> /dev/null
                unset WMULTIPLIER
                unset SNAPSHOT
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        function efficiency_hy_javascript {
            for benchmark in $JS_HY_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export SNAPSHOT=$snapshots/$benchmark
                bash -c "export ITERATIONS=1; $(DIR)/benchmark-hydra.sh vm $benchmark test 100"
                $(DIR)/benchmark-hydra.sh vm $benchmark benchmark 1
                rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
                unset SNAPSHOT
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        function efficiency_hy_python {
            for benchmark in $PY_HY_BENCHMARKS;
            do
                export VM_MEM=${mem_table["$benchmark"]}
                export CGROUP_CPU_QUOTA=${cpu_table["$benchmark"]}
                export SNAPSHOT=$snapshots/$benchmark
                bash -c "export ITERATIONS=1; $(DIR)/benchmark-hydra.sh vm $benchmark test 100"
                export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
                $(DIR)/benchmark-hydra.sh vm $benchmark benchmark 1
                rm $SNAPSHOT.{disk,mem,snap} &> /dev/null
                unset WMULTIPLIER
                unset SNAPSHOT
                unset CGROUP_CPU_QUOTA
                unset VM_MEM
            done
        }

        export SANDBOX="isolate"; efficiency_hy_java; unset SANDBOX
        export SANDBOX="context"; efficiency_hy_javascript; unset SANDBOX
        export SANDBOX="context"; efficiency_hy_python; unset SANDBOX
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

    # Knative runtimes
    function efficiency_kn {
        for benchmark in $KN_BENCHMARKS;
        do
            export WMULTIPLIER=${wmultiplier_table["$benchmark"]}
            $(DIR)/benchmark-knative.sh $benchmark benchmark ${concurrency_table["$benchmark"]}
            unset WMULTIPLIER
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

    efficiency_hy
    efficiency_hy_single
    # efficiency_hy_snapshot
    efficiency_cr
    efficiency_kn

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
read -p "Run basic hydra tests (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    test_hy_benchmarks
    exit 0
fi

read -p "Run basic openwhisk tests (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    test_ow_benchmarks
    exit 0
fi

read -p "Run basic knative tests (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    test_kn_benchmarks
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
