#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Move into the script directory.
cd $DIR &> /dev/null

npm install

zip -r action.zip main.js package.json node_modules
base64 --wrap=0 action.zip > action.zip.base64
cat action.zip.base64 | jq -sR  '{value: {main: "main", binary: "True", code: .}}' > init.json
