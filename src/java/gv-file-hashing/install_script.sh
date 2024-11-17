#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

cp $DIR/build/libfilehashing.so $1/gv-file-hashing.so
