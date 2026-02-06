#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Move into the script directory.
cd $DIR &> /dev/null

# Check if 'func' is available.
if ! command -v func >/dev/null 2>&1
then
    echo "The 'func' tool could not be found. Please download 'func': https://github.com/knative/func/releases."
    echo "Once downloaded, make sure to put it on your PATH to build the benchmark."
    echo "This tool is needed to build the Knative benchmarks as Docker container images."
    exit 1
fi

# Build container image.
func build
