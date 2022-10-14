#!/bin/bash

if [ $# -eq 0 ]; then
    echo "usage $0 iter_count"
    exit 1
fi

set -xe;

source=test_mmap_anon
tests=(
    mmap_no_init_bench
    mmap_init_bench
    mmap_no_init_no_unmap_bench
    mmap_init_no_unmap_bench
)

gcc $source.c -o $source.out -Wall -Wextra
for test in "${tests[@]}"; do
    ./$source.out $test $@ > $test.log;
done
