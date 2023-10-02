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
./gradlew -Dorg.gradle.java.home=$JAVA_HOME clean shadowJar assemble

# Prepare init json.
body=$(base64 --wrap=0 build/libs/videoprocessing-1.0-all.jar)
echo "{ \"value\": { \"binary\": \"True\", \"main\": \"com.videoprocessing.VideoProcessing\", \"code\": \"$body\" } }" > init.json
