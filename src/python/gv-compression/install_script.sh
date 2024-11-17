#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

cp $DIR/build/libcompression.so $1/gv-py-compression.so
