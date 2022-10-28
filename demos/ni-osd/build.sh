#!/bin/bash

. ./.env

echo "JAVA_HOME=$JAVA_HOME"
echo "GRAALVM_HOME=$GRAALVM_HOME"

if [ -z "$JAVA_HOME" ]
then
    echo "JAVA_HOME is not set"
	exit 1
fi

if [ ! -f "$GRAALVM_HOME"/bin/native-image ]
then
    echo "native-image is missing"
	exit 1
fi

function build_app {
	cd build
	$GRAALVM_HOME/bin/native-image \
		--no-fallback \
		-H:ReflectionConfigurationFiles=../reflect.json \
		-cp libs/demo-ni-osd-1.0-all.jar\
		-H:+ReportExceptionStackTraces \
		-H:Name=demoosd \
            com.demo_ni_osd.DemoOSD
}

./gradlew clean shadowJar assemble

build_app
