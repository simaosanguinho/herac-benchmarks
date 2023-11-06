#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

$(DIR)/run-experiment.sh 1
$(DIR)/run-experiment.sh 2
$(DIR)/run-experiment.sh 4
$(DIR)/run-experiment.sh 8
$(DIR)/run-experiment.sh 16
$(DIR)/run-experiment.sh 32
$(DIR)/run-experiment.sh 64
$(DIR)/run-experiment.sh 128
$(DIR)/run-experiment.sh 256
