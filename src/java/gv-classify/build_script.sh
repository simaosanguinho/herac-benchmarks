#!/bin/bash

function DIR {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

function run_agent {
	rm -rf config-dir
	$JAVA_HOME/bin/java \
		-Djava.awt.headless=true \
		-agentlib:native-image-agent=config-output-dir=config-dir/ \
		-cp build/libs/classify-1.0-all.jar \
		com.classify.Classify
}

function build_graalvisor_app {
	cd build
	$JAVA_HOME/bin/native-image \
		--no-fallback \
		--enable-url-protocols=http \
		-Djava.awt.headless=true \
		-cp libs/classify-1.0-all.jar\
		-DGraalVisorGuest=true \
		-Dcom.oracle.svm.graalvisor.libraryPath=resources/main/com.oracle.svm.graalvisor.headers \
		--initialize-at-run-time=com.oracle.svm.graalvisor.utils.JsonUtils \
		-H:ConfigurationFileDirectories=../ni-agent-config,../config-dir \
		-H:+ReportExceptionStackTraces \
		--shared \
		-H:Name=libclassify
}

./gradlew clean shadowJar assemble
#run_agent
build_graalvisor_app

echo BENCHMARK_PATH=$(DIR)/build/libs/videoprocessing-1.0.jar
