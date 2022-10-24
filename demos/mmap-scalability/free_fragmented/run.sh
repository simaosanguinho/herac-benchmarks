#!/bin/bash

tests=(
    free_one_chunk
    free_all_chunks
)

source ../compile_run.sh test_free_fragmented $@
