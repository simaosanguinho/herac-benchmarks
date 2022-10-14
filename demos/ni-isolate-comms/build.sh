#!/bin/bash

if [ -z "$JAVA_HOME" ]
then
    echo "JAVA_HOME is not set"
	exit 1
fi

if [ ! -f "$JAVA_HOME"/bin/native-image ]
then
    echo "native-image is missing"
	exit 1
fi

function build_app {
	cd build
	$JAVA_HOME/bin/native-image \
		--no-fallback \
		-H:ReflectionConfigurationFiles=../reflect.json \
		-cp libs/demo-ni-isolate-comms-1.0-all.jar\
		-H:+ReportExceptionStackTraces \
		-H:Name=demoisolatecomms \
            com.demo_ni_isolate_comms.DemoIsolateComms
}

./gradlew clean shadowJar assemble

build_app
