#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

if [ -f $(DIR)/../../env.sh ]; then
    source $(DIR)/../../env.sh
fi

if [ -z "${ARGO_HOME}" ]; then
    echo "ARGO_HOME is not defined. Existing..."
    exit 1
fi
if [ -z "${JAVA_HOME}" ]; then
    echo "JAVA_HOME is not defined. Existing..."
    exit 1
fi
if [ -z "${WORK_DIR}" ]; then
    echo "WORK_DIR is not defined. Existing..."
    exit 1
fi

export BENCHMARKS_HOME=$(DIR)/..
export GRAALVISOR_HOME=$ARGO_HOME/graalvisor
export GRAALHOST_HOME=
export RESOURCES_HOME=$ARGO_HOME/resources
export GRAALVISOR_PORT=8081
export GRAALHOST_PORT=8100
export OPENWHISK_PORT=8080
export KNATIVE_PORT=8082
export TDIR=$WORK_DIR/bench
export ADIR=$WORK_DIR/apps
export SDIR=$WORK_DIR/snaps
