#!/bin/bash

tests=(
    free_no_init
    free_init
)

source ../compile_run.sh test_free $@
