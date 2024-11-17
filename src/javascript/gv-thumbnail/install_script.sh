#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

cp $DIR/build/libthumbnail.so $1/gv-js-thumbnail.so
