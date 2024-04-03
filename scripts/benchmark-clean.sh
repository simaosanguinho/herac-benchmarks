#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/shared.sh

pkill -f benchmark-cruntime.sh
pkill -f benchmark-graalvisor.sh
stop_svm       &> /dev/null
stop_container &> /dev/null
stop_vm        &> /dev/null

rm -rf $TDIR
rm -rf $ADIR
rm -rf $SDIR
