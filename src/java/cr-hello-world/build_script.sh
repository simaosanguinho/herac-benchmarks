#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

DOCKER_COMMAND="docker run --rm --user $(id -u):$(id -g) -v $DIR:$DIR -w $DIR eclipse-temurin:8-jdk-ubi10-minimal bash -c"

# Move into the script directory.
cd $DIR &> /dev/null

# Build and package.
$DOCKER_COMMAND "javac -cp gson-2.8.6.jar Hello.java && jar cvf hello.jar Hello.class"

# Prepare init json.
body=$(base64 --wrap=0 hello.jar)
echo "{ \"value\": { \"binary\": \"True\", \"main\": \"Hello\", \"code\": \"$body\" } }" > init.json
