#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

function genericapp {
    PORT=$1
    APP_SO=$ARGO_HOME/benchmarks/src/java/gv-genericapp/build/libgenericapp.so
    curl -w "\n" -s -X POST 127.0.0.1:$PORT/register?name=genericapp\&entryPoint=com.genericapp.GenericApp\&language=java -H 'Content-Type: application/json' --data-binary @$APP_SO
    echo '{"name":"genericapp","arguments":"{\"memory\":\"4000000\",\"duration\":\"1000\"}"}' > $(DIR)/genericapp.post
}

function load_worker {
    WORKER_ID=$1
    PORT=$2
    PID=$(cat $(DIR)/workers/$WORKER_ID.pid)
    genericapp $PORT
    while sudo kill -0 $PID &> /dev/null; do
        curl -w "\n" -s -X POST 127.0.0.1:$PORT -H 'Content-Type: application/json' -d $(cat $(DIR)/genericapp.post)
    done
}

if [ -z "${ARGO_HOME}" ]; then
    echo "ARGO_HOME is not defined. Existing..."
    exit 1
fi

if [ -z "$1" ]; then
    WORKERS=1
else
    WORKERS=$1
fi

mkdir -p $(DIR)/workers &> /dev/null
mkdir -p $(DIR)/results/$WORKERS &> /dev/null

for id in $(seq $WORKERS)
do
    WORKER_ID="worker-$id"
    WORKER_PORT=$((8080 + $id))
    echo "Creating worker $id ($WORKER_ID:$WORKER_PORT) out of $WORKERS"
    sudo ARGO_HOME=$ARGO_HOME $(DIR)/run-worker.sh $WORKER_ID $WORKER_PORT
    sleep 1 # Let the worker start.
    load_worker $WORKER_ID $WORKER_PORT &> $(DIR)/workers/$WORKER_ID.load &
done

sleep 10

for id in $(seq $WORKERS)
do
    WORKER_ID="worker-$id"
    echo "Destroying worker $id ($WORKER_ID) out of $WORKERS"
    sudo ARGO_HOME=$ARGO_HOME $(DIR)/kill-worker.sh $WORKER_ID
done

# Saving results.
cp $(DIR)/workers/*.load $(DIR)/results/$WORKERS

# Delete working directories.
sudo rm -r $(DIR)/workers
