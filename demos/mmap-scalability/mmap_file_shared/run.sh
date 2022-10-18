#!/bin/bash

tests=(
    mmap_no_init_bench
    mmap_init_bench
    mmap_no_init_no_unmap_bench
    mmap_init_no_unmap_bench
)

source ../compile_run.sh test_mmap_file_shared $@
