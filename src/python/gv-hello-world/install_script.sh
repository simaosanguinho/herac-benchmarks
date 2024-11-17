#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

cp $DIR/build/libhelloworld.so $1/gv-py-hello-world.so
