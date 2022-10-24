#!/bin/bash

tests=(
    mmap_no_init
    mmap_init
    mmap_no_init_no_unmap
    mmap_init_no_unmap
)

source ../compile_run.sh test_mmap_file_shared $@
