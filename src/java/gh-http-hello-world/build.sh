#!/bin/bash

if [ -z "$GRAALOS_HOME" ]
then
        echo "Please set GRAALOS_HOME first. It should point to a checkout of graalos sdk."
        exit 1
fi

$GRAALOS_HOME/scripts/build-env-rc.sh ./gradlew nativeCompile
