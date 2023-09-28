#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ -z "$JAVA_HOME" ]
then
        echo "Please set JAVA_HOME first. It should be a Java 8 distribution."
        exit 1
fi

# Move into the script directory.
cd $DIR &> /dev/null

# Build and package.
$JAVA_HOME/bin/javac -cp gson-2.8.6.jar Main.java
$JAVA_HOME/bin/jar cvf Main.jar Main.class

# Prepare init json.
body=$(base64 --wrap=0 Main.jar)
echo "{ \"value\": { \"binary\": \"True\", \"main\": \"Main\", \"code\": \"$body\" } }" > init.json
