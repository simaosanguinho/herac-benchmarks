#!/bin/bash

tests=(
    malloc_no_init_bench
    malloc_init_bench
    malloc_no_init_no_free_bench
    malloc_init_no_free_bench
)

source ../compile_run.sh test_malloc_fragmented $@
