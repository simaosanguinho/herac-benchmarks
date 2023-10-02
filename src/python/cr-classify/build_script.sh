#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ -z "$PYTHON_HOME" ]
then
        echo "Please set PYTHON_HOME first. It should be a Python 3 distribution."
        exit 1
fi

# Move into the script directory.
cd $DIR &> /dev/null

# Preparing the virtual env.
$PYTHON_HOME/python -m venv virtualenv
cp ../activate_this.py virtualenv/bin/activate_this.py
source virtualenv/bin/activate

# Installing dependencies.
pip install requests
pip install torch
pip install torchvision

# Packaging.
zip -r action.zip __main__.py virtualenv
base64 --wrap=0 action.zip > action.zip.base64
cat action.zip.base64 | jq -sR  '{value: {main: "main", binary: true, code: .}}' > init.json
