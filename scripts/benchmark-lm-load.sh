#!/bin/bash

# Example usage of this script:
# bash benchmark-lm-load.sh gv|cr|ph /path/to/dataset/file
# The structure of the .csv file should be as follows:
# HashOwner HashFunction AverageAllocatedMb AverageDuration Timestamp

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}


function process_dataset {
    csv_file=$1
    function_runtime=$2
    invocation_collocation=$3
    function_isolation=$4
    gv_sandbox=$5  # should be the last parameter since it can be empty

    AZURE_EXECUTOR_JAR=$(DIR)/../azure-dataset/build/libs/azure-dataset-1.0-all.jar
    AZURE_EXECUTOR_ENTRYPOINT=org.graalvm.argo.dataset.execution.ExecutorEntryPoint

    GV_SANDBOX_OPTION=
    if [ -n "$gv_sandbox" ]
    then
        GV_SANDBOX_OPTION="--gvSandbox $gv_sandbox"
    fi

    time $JAVA_HOME/bin/java -cp $AZURE_EXECUTOR_JAR $AZURE_EXECUTOR_ENTRYPOINT \
        --input $csv_file \
        --functionRuntime $function_runtime \
        --invocationCollocation $invocation_collocation \
        --functionIsolation $function_isolation \
        # --multiWorker \
        $GV_SANDBOX_OPTION > /tmp/lse_executor.log

    wait

    sleep 10
    echo "Finished benchmark execution. Stopping the lambda manager..."
    echo "--- Execute this command to kill LM: ---"
    echo "sudo kill $(sudo lsof -i -P -n | grep LISTEN | grep 30009 | awk '{print $2}')"
    sudo kill $(sudo lsof -i -P -n | grep LISTEN | grep 30009 | awk '{print $2}')
}


function wait_port {
    host=$1
    port=$2
    while ! nc -z $host $port; do echo "Waiting for $host:$port"; sleep 1; done
}


MODE=$1
DATASET_FILE=$2
ARGO_HOME=$(DIR)/../../argo/
RUN_HOME=$ARGO_HOME/run/bin
LAMBDA_MANAGER_CONFIG=$ARGO_HOME/run/configs/manager/default-lambda-manager.json
LAMBDA_MANAGER_HOST=localhost
LAMBDA_MANAGER_PORT=30009
LAMBDA_MANAGER_ADDRESS="$LAMBDA_MANAGER_HOST:$LAMBDA_MANAGER_PORT"


if [[ "$MODE" = "gv" ]]; then
    FUNCTION_RUNTIME=graalvisor
    FUNCTION_ISOLATION=false
    INVOCATION_COLLOCATION=true
elif [[ "$MODE" = "gv-sf" ]]; then
    FUNCTION_RUNTIME=graalvisor
    FUNCTION_ISOLATION=true
    INVOCATION_COLLOCATION=true
elif [[ "$MODE" = "gv-si" ]]; then
    FUNCTION_RUNTIME=graalvisor
    FUNCTION_ISOLATION=true
    INVOCATION_COLLOCATION=false
elif [[ "$MODE" = "ow" ]]; then
    FUNCTION_RUNTIME=openwhisk
    FUNCTION_ISOLATION=true
    INVOCATION_COLLOCATION=false
elif [[ "$MODE" = "ow-uber" ]]; then
    FUNCTION_RUNTIME=openwhisk_uber
    FUNCTION_ISOLATION=true
    INVOCATION_COLLOCATION=false
else
    echo "Syntax: <mode> </path/to/dataset/directory>"
	exit 1
fi


# Deploy lambda manager and wait for it to launch
$RUN_HOME/run deploy lm &
wait_port $LAMBDA_MANAGER_HOST $LAMBDA_MANAGER_PORT

# Configure lambda manager
curl -s -X POST $LAMBDA_MANAGER_ADDRESS/configure_manager -H 'Content-Type: application/json' --data-binary @"$LAMBDA_MANAGER_CONFIG"

process_dataset $DATASET_FILE $FUNCTION_RUNTIME $INVOCATION_COLLOCATION $FUNCTION_ISOLATION $GV_SANDBOX &

wait
