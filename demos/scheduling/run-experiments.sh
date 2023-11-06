#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

$(DIR)/run-experiment.sh 1
$(DIR)/run-experiment.sh 2
$(DIR)/run-experiment.sh 4
$(DIR)/run-experiment.sh 8
