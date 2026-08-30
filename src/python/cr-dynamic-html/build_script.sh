#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ -z "$PYTHON_HOME" ]
then
        echo "Please set PYTHON_HOME first. It should be a Python 3 distribution."
        exit 1
fi

# Move into the script directory.
cd $DIR &> /dev/null
rm -rf virtualenv action.zip action.zip.base64 init.json activate_this.py
ACTIVATE_THIS_SOURCE="../activate_this.py"
if [ ! -f "$ACTIVATE_THIS_SOURCE" ] && [ -n "$ARGO_HOME" ]; then
        ACTIVATE_THIS_SOURCE="$ARGO_HOME/benchmarks/src/python/activate_this.py"
fi

# Preparing the virtual env.
$PYTHON_HOME/python -m venv virtualenv
cp "$ACTIVATE_THIS_SOURCE" virtualenv/bin/activate_this.py
cp "$ACTIVATE_THIS_SOURCE" .
source virtualenv/bin/activate

# Installing dependencies.
pip install requests
pip install pystache

# Packaging.
zip -r action.zip __main__.py activate_this.py virtualenv
base64 --wrap=0 action.zip > action.zip.base64
$PYTHON_HOME/python - <<'PY'
import json
from pathlib import Path

code = Path("action.zip.base64").read_text(encoding="utf-8")
Path("init.json").write_text(json.dumps({"value": {"main": "main", "binary": True, "code": code}}, indent=2) + "\n", encoding="utf-8")
PY
