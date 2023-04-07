#!/bin/bash

function DIR {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

function build_graalvisor_app {
	cd build
	$JAVA_HOME/bin/native-image \
		--no-fallback \
		--enable-url-protocols=http \
		-cp libs/filehashing-1.0-all.jar\
		-DGraalVisorGuest=true \
		-Dcom.oracle.svm.graalvisor.libraryPath=resources/main/com.oracle.svm.graalvisor.headers \
		--initialize-at-run-time=com.oracle.svm.graalvisor.utils.JsonUtils \
		-H:ConfigurationFileDirectories=../ni-agent-config \
		-H:+ReportExceptionStackTraces \
		--shared \
		-H:Name=libfilehashing
}

if [ -z "$ARGO_HOME" ]
then
        echo "Please set ARGO_HOME first. It should point to a checkout of github.com/graalvm/argo."
        exit 1
fi

if [ -z "$JAVA_HOME" ]
then
        echo "Please set JAVA_HOME first. It should be a GraalVM with native-image available."
        exit 1
fi

./gradlew clean shadowJar assemble

build_graalvisor_app

echo BENCHMARK_PATH=$(DIR)/build/libs/filehashing-1.0.jar
