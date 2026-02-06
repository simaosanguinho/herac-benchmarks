#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

DOCKER_COMMAND="docker run --rm --user $(id -u):$(id -g) -v $DIR:$DIR -w $DIR eclipse-temurin:8-jdk-ubi10-minimal bash -c"

# Move into the script directory.
cd $DIR &> /dev/null

# Build and package.
$DOCKER_COMMAND "./gradlew clean shadowJar assemble"

# Prepare init json.
body=$(base64 --wrap=0 build/libs/videoprocessing-1.0-all.jar)
echo "{ \"value\": { \"binary\": \"True\", \"main\": \"com.videoprocessing.VideoProcessing\", \"code\": \"$body\" } }" > init.json
