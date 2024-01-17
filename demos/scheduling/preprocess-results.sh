#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

for worker in 1 2 4 8 16 32 64 128 256
do
    wdir=$(DIR)/results/$worker/
    # Extract wait time
    perf sched timehist --input $wdir/worker.perf | grep -v "Handler" | awk '{print $4}'| tail -n +4 | ~/git/helper-scripts/math/average.py > $wdir/wait.time
    # Extract sched time
    perf sched timehist --input $wdir/worker.perf | grep -v "Handler" | awk '{print $5}'| tail -n +4 | ~/git/helper-scripts/math/average.py > $wdir/sched.time
done