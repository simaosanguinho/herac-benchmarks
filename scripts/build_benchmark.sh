#!/bin/bash

# This script builds the benchmark with argo-builder container.
# The absolute path to the build script is specified as the first parameter.
#
# Example usage: build_benchmark.sh /absolute/path/to/gv-hello-world/build_script.sh
#
# This script assumes that the user has the argo-builder container
# locally. It can be built by running $ARGO_HOME/builder/build.sh.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ -z "$ARGO_HOME" ]
then
    echo "Please set ARGO_HOME first. It should point to a checkout of github.com/graalvm/argo."
    exit 1
fi

if [ -z "$JAVA_HOME" ]
then
    echo "Please set JAVA_HOME first. It should be a GraalVM with native-image available."
    exit 1
fi

BENCHMARK_BUILD_SCRIPT=$1
if [ -z "$BENCHMARK_BUILD_SCRIPT" ]
then
    echo "Path to the build script is not present."
    exit 1
fi

BENCHMARK_SCRIPT_BASENAME="$(basename -- $BENCHMARK_BUILD_SCRIPT)"
BENCHMARK_HOME="$(dirname -- $BENCHMARK_BUILD_SCRIPT)"

docker run -it -v $JAVA_HOME:/jvm -v $ARGO_HOME:/argo -v $BENCHMARK_HOME:/benchmark-home -w /benchmark-home --rm argo-builder /benchmark-home/$BENCHMARK_SCRIPT_BASENAME
sudo chown -R $USER:$USER $BENCHMARK_HOME/build
