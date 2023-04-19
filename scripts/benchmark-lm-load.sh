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
    function_code=$2
    function_name=$3
    function_entry_point=$4
    function_runtime=$5
    invocation_collocation=$6
    function_isolation=$7
    gv_sandbox=$8  # should be the last parameter since it can be empty

    # This will be used as a set to know which functions have already been uploaded
    declare -A setUploadedOwners

    current_timestamp=0
    tail -n +2 $csv_file |
    while IFS=, read -r HashOwner HashFunction AverageAllocatedMb AverageDuration Timestamp
    do
        if [ -z "${setUploadedOwners[$HashFunction]}" ]
        then
            # Upload function for current owner and set as uploaded to prevent uploading it more than once
            query_parameters="username=$HashOwner&function_name=$HashFunction"
            query_parameters="$query_parameters&function_language=java&function_entry_point=$function_entry_point"
            query_parameters="$query_parameters&function_memory=128&function_runtime=$function_runtime"
            query_parameters="$query_parameters&function_isolation=$function_isolation&invocation_collocation=$invocation_collocation"
            if [ -n "$gv_sandbox" ]
            then
                query_parameters="$query_parameters&gv_sandbox=$gv_sandbox"
            fi

            curl -s -X POST $LAMBDA_MANAGER_ADDRESS/upload_function?"$query_parameters" -H 'Content-Type: application/octet-stream' --data-binary @"$function_code" > /dev/null
            setUploadedOwners["$HashFunction"]=1
        fi

        # This is just to adjust the start of the requests with the beginning of the hour
        time_to_sleep=$(python3 -c "print((($Timestamp - $current_timestamp) % 3600000) / 1000)")
        allocated_memory=$(python3 -c "print(int(($AverageAllocatedMb * 1024 * 1024) * 0.05))")
        current_timestamp=$Timestamp
        sleep $time_to_sleep
        # TODO: try with real trace values
        curl -s -X POST $LAMBDA_MANAGER_ADDRESS/$HashOwner/$HashFunction -H 'Content-Type: application/json' --data '{"memory":"'$allocated_memory'","duration":"'$AverageDuration'"}' &
    done
    wait

    sleep 60
    echo "Finished benchmark execution. Stopping the lambda manager..."
    echo "--- Execute this command to kill LM: ---"
    echo "sudo kill $(sudo lsof -i -P -n | grep LISTEN | grep 30009 | awk '{print $2}')"
}


function log_metrics {
    response=$(curl -s --max-time 60 $LAMBDA_MANAGER_ADDRESS/metrics)
    echo "$response" | grep system_footprint | awk '{print $2}' >> $FOOTPRINT_METRICS_FILENAME
    echo "$response" | grep cold_start_latency_max | awk '{print $2}' >> $MAX_LATENCY_METRICS_FILENAME
    echo "$response" | grep cold_start_latency_avg | awk '{print $2}' >> $AVG_LATENCY_METRICS_FILENAME
    echo "$response" | grep open_requests | awk '{print $2}' >> $OPEN_REQUESTS_METRICS_FILENAME
    echo "$response" | grep active_lambdas | awk '{print $2}' >> $ACTIVE_LAMBDAS_METRICS_FILENAME
    echo "$response" | grep active_users | awk '{print $2}' >> $ACTIVE_USERS_METRICS_FILENAME
    echo "$response" | grep throughput | awk '{print $2}' >> $THROUGHPUT_METRICS_FILENAME
}


function start_metrics_scraper {
    alive=true
    while [ "$alive" = "true" ]
    do
        alive=false
        log_metrics &

        sleep 1

        if ps -p $FUNCTION_PID > /dev/null
        then
            alive=true
        fi
    done
}


MODE=$1
DATASET_FILE=$2
ARGO_HOME=$(DIR)/../../argo/
RUN_HOME=$ARGO_HOME/run/bin
LAMBDA_MANAGER_CONFIG=$ARGO_HOME/run/configs/manager/default-lambda-manager.json
LAMBDA_MANAGER_ADDRESS=localhost:30009
FOOTPRINT_METRICS_FILENAME=footprint.txt
MAX_LATENCY_METRICS_FILENAME=max_latency.txt
AVG_LATENCY_METRICS_FILENAME=avg_latency.txt
OPEN_REQUESTS_METRICS_FILENAME=open_requests.txt
ACTIVE_LAMBDAS_METRICS_FILENAME=active_lambdas.txt
ACTIVE_USERS_METRICS_FILENAME=active_users.txt
THROUGHPUT_METRICS_FILENAME=throughput.txt

if [[ "$MODE" = "gv" ]]; then
    FUNCTION_CODE=$ARGO_HOME/../benchmarks/src/java/gv-genericapp/build/libgenericapp.so
    FUNCTION_NAME=gvgenericappbench
    FUNCTION_ENTRY_POINT=com.genericapp.GenericApp
    FUNCTION_RUNTIME=docker.io%2Fsergiyivan%2Flarge-scale-experiment:graalvisor
    FUNCTION_ISOLATION=false
    INVOCATION_COLLOCATION=true
elif [[ "$MODE" = "gv-fork" ]]; then
    FUNCTION_CODE=$ARGO_HOME/../benchmarks/src/java/gv-genericapp/build/libgenericapp.so
    FUNCTION_NAME=gvgenericappbench
    FUNCTION_ENTRY_POINT=com.genericapp.GenericApp
    FUNCTION_RUNTIME=docker.io%2Fsergiyivan%2Flarge-scale-experiment:graalvisor
    FUNCTION_ISOLATION=true
    INVOCATION_COLLOCATION=true
    GV_SANDBOX=process
elif [[ "$MODE" = "cr" ]]; then
    FUNCTION_CODE=$ARGO_HOME/../benchmarks/src/java/cr-genericapp/init.json
    FUNCTION_NAME=crgenericappbench
    FUNCTION_ENTRY_POINT=Main
    FUNCTION_RUNTIME=docker.io%2Fopenwhisk%2Fjava8action:latest
    FUNCTION_ISOLATION=false  # We don't care about this value for OpenWhisk as functions are isolated there by default
    INVOCATION_COLLOCATION=false
elif [[ "$MODE" = "ph" ]]; then
    FUNCTION_CODE=$ARGO_HOME/../benchmarks/src/java/cr-genericapp/init.json
    FUNCTION_NAME=phgenericappbench
    FUNCTION_ENTRY_POINT=Main
    FUNCTION_RUNTIME=docker.io%2Fsergiyivan%2Flarge-scale-experiment:photons
    FUNCTION_ISOLATION=false  # We don't care about this value for Photons as functions are isolated there by default
    INVOCATION_COLLOCATION=true
else
    echo "Syntax: <gv|cr|ph> /path/to/dataset/directory"
	exit 1
fi


# Deploy lambda manager and wait for it to launch
$RUN_HOME/run deploy lm &
sleep 5

# Configure lambda manager
curl -s -X POST $LAMBDA_MANAGER_ADDRESS/configure_manager -H 'Content-Type: application/json' --data-binary @"$LAMBDA_MANAGER_CONFIG"

echo -n "" > $FOOTPRINT_METRICS_FILENAME
echo -n "" > $MAX_LATENCY_METRICS_FILENAME
echo -n "" > $AVG_LATENCY_METRICS_FILENAME
echo -n "" > $OPEN_REQUESTS_METRICS_FILENAME
echo -n "" > $ACTIVE_LAMBDAS_METRICS_FILENAME
echo -n "" > $ACTIVE_USERS_METRICS_FILENAME
echo -n "" > $THROUGHPUT_METRICS_FILENAME

process_dataset $DATASET_FILE $FUNCTION_CODE $FUNCTION_NAME $FUNCTION_ENTRY_POINT $FUNCTION_RUNTIME $INVOCATION_COLLOCATION $FUNCTION_ISOLATION $GV_SANDBOX &
FUNCTION_PID=$!
start_metrics_scraper &

wait
