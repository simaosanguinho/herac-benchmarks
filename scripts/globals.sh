#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

if [ -z "${ARGO_HOME}" ]; then
    echo "ARGO_HOME is not defined. Existing..."
    exit 1
fi
if [ -z "${JAVA_HOME}" ]; then
    echo "JAVA_HOME is not defined. Existing..."
    exit 1
fi
if [ -z "${WORK_DIR}" ]; then
    echo "Temporary working dir not defined. Existing..."
    exit 1
fi

export BENCHMARKS_HOME=$(DIR)/..
export GRAALVISOR_HOME=$ARGO_HOME/graalvisor
export RESOURCES_HOME=$ARGO_HOME/resources
export GRAALVISOR_PORT=8081
export OPENWHISK_PORT=8080
export TDIR=$WORK_DIR/bench
export ADIR=$WORK_DIR/apps
export SDIR=$WORK_DIR/snaps
