#!/bin/bash

# This script builds the benchmark with argo-builder container or locally.
# The path to the build script is specified as the first parameter.
# The build mode (local or container) is specified as the second parameter.
#
# Example usage: build_benchmark.sh /path/to/hy-hello-world/build_script.sh
#
# The env varialble BENCHMARK_BUILD_MODE is used to decice if the build script
# is called on the local environment or inside the argo build container. It can
# take two values: local and container.
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
else
    eval $(echo "export $(cat $JAVA_HOME/release | grep GRAALVM_VERSION=)")
fi

BENCHMARK_BUILD_SCRIPT=$1
if [ -z "$BENCHMARK_BUILD_SCRIPT" ]
then
    echo "Path to the build script is not present."
    echo "Example usage: build_benchmark.sh /path/to/hy-hello-world/build_script.sh"
    exit 1
else
    BENCHMARK_BUILD_SCRIPT=$(realpath $BENCHMARK_BUILD_SCRIPT)
fi

if [ -z "$BENCHMARK_BUILD_MODE" ]
then
    echo "Warning: build mode is not present. Defaultin to local build mode."
    BENCHMARK_BUILD_MODE="local"
fi

# This will remove the benchmark build script from $@ so that we can pass it.
shift

# Some benchmarks cannot still be compiled with GraalVM 23 (Java 17).
if [[ $BENCHMARK_BUILD_SCRIPT == *"/java/hy-classify"* ]]; then
    if [[ $GRAALVM_VERSION == *"23.0.0"* ]]; then
        export JAVA_HOME=$JAVA11_HOME
    fi
elif [[ $BENCHMARK_BUILD_SCRIPT == *"/javascript/hy-thumbnail"* ]]; then
    if [[ $GRAALVM_VERSION == *"23.0.0"* ]]; then
        export JAVA_HOME=$JAVA11_HOME
    fi
fi

# Java openwhisk benchmarks needs to be compiled with Java 8.
if [[ $BENCHMARK_BUILD_SCRIPT == *"java/cr-"* ]]; then
    export JAVA_HOME=$JAVA8_HOME
fi

if [ "$BENCHMARK_BUILD_MODE" == "container" ]; then
    BENCHMARK_SCRIPT_BASENAME="$(basename -- $BENCHMARK_BUILD_SCRIPT)"
    BENCHMARK_HOME="$(dirname -- $BENCHMARK_BUILD_SCRIPT)"
    CONTAINER_IMAGE="argo-builder"
    DOCKER_TTY_ARGS=( -i )
    if [ -t 1 ]; then
        DOCKER_TTY_ARGS+=( -t )
    fi
    docker_args=(
        run
        "${DOCKER_TTY_ARGS[@]}"
        --rm
        --user "$(id -u):$(id -g)"
        -e HOME=/tmp/build-home
        -e ARGO_HOME=/argo
        -e JAVA_HOME=/jvm
        -e PYTHON_HOME=/usr/bin
        -v "$JAVA_HOME:/jvm"
        -v "$ARGO_HOME:/argo"
        -v "$BENCHMARK_HOME:/benchmark-home"
        -w /benchmark-home
    )

    if [[ $BENCHMARK_BUILD_SCRIPT == *"python/cr-"* ]]; then
        CONTAINER_IMAGE="openwhisk/action-python-v3.9:latest"
        docker_args=(
            run
            "${DOCKER_TTY_ARGS[@]}"
            --rm
            --entrypoint bash
            --user "$(id -u):$(id -g)"
            -e HOME=/tmp/build-home
            -e ARGO_HOME=/argo
            -e PYTHON_HOME=/usr/local/bin
            -v "$ARGO_HOME:/argo"
            -v "$BENCHMARK_HOME:/benchmark-home"
            -w /benchmark-home
        )
    fi

    docker "${docker_args[@]}" \
        "$CONTAINER_IMAGE" \
        "/benchmark-home/$BENCHMARK_SCRIPT_BASENAME" "$@"
elif [ "$BENCHMARK_BUILD_MODE" == "local" ]; then
        bash $BENCHMARK_BUILD_SCRIPT $@
else
    echo "Invalid build mode."
    echo "Example usage: build_benchmark.sh /path/to/hy-hello-world/build_script.sh"
    exit 1
fi
