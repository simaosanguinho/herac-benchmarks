#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

cp $DIR/build/libclassify.so $1/gv-classify.so
