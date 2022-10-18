#!/bin/bash

set -xe;

source=$1
gcc $source.c ../utils/*.c -o $source.out -Wall -Wextra

shift

for test in "${tests[@]}"; do
    ./$source.out $test $@ > $test.log 2>&1;
done
