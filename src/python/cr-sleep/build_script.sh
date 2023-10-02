#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Move into the script directory.
cd $DIR &> /dev/null

cat main.py | jq -sR  '{value: {name: "python-sleep",  main: "main", binary: false, code: .}}' > init.json
