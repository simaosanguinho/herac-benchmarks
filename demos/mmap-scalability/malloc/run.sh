#!/bin/bash

if [ $# -eq 0 ]; then
    echo "usage $0 iter_count"
    exit 1
fi

set -xe;

source=test_malloc
tests=(
    malloc_no_init_bench
    malloc_init_bench
    malloc_no_init_no_free_bench
    malloc_init_no_free_bench
)

gcc $source.c -o $source.out -Wall -Wextra
for test in "${tests[@]}"; do
    ./$source.out $test $@ > $test.log;
done
