#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/shared.sh

stop_svm       &> /dev/null
stop_container &> /dev/null
stop_vm        &> /dev/null

rm -rf $TDIR &> /dev/null