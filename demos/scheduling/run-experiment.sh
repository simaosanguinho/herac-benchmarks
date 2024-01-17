#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

function genericapp {
    APP_SO=$ARGO_HOME/benchmarks/src/java/gv-genericapp/build/libgenericapp.so
    curl -w "\n" -s -X POST 127.0.0.1:8080/register?name=genericapp\&entryPoint=com.genericapp.GenericApp\&language=java -H 'Content-Type: application/json' --data-binary @$APP_SO
    echo '{"name":"genericapp","arguments":"{\"memory\":\"4096\",\"duration\":\"100\"}"}' > $(DIR)/genericapp.post
}

function load_worker {
    PID=$(cat $(DIR)/worker/worker.pid)
    genericapp
    while kill -0 $PID &> /dev/null; do
        curl -w "\n" -s -X POST 127.0.0.1:8080 -H 'Content-Type: application/json' -d $(cat $(DIR)/genericapp.post)
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

mkdir -p $(DIR)/worker &> /dev/null
mkdir -p $(DIR)/results/$WORKERS &> /dev/null

ARGO_HOME=$ARGO_HOME $(DIR)/run-worker.sh

sleep 1 # Let the worker start.

for id in $(seq $WORKERS)
do
    load_worker &> $(DIR)/worker/worker.load &
done

sleep 30

ARGO_HOME=$ARGO_HOME $(DIR)/kill-worker.sh

# Change worker ownership (because of perf).
sudo chown -R $(id -u -n):$(id -g -n) $(DIR)/worker

# Saving results.
rm -r $(DIR)/results/$WORKERS &> /dev/null
mv $(DIR)/worker $(DIR)/results/$WORKERS
