#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

cat $DIR/main.js | jq -sR  '{value: {main: "main", code: .}}' > $DIR/init.json
