#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

zip --junk-paths $1/gv-jv-classify.zip $DIR/build/*.so $DIR/build/*.h
