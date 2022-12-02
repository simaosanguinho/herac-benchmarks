#!/bin/bash

tests=(
    malloc_no_init
    malloc_init
    malloc_no_init_no_free
    malloc_init_no_free
)

source ../compile_run.sh test_malloc $@
