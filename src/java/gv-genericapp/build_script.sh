#!/bin/bash

function DIR {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

function run_app {
	/usr/bin/time -v $JAVA_HOME/bin/java -cp build/libs/genericapp-1.0-all.jar com.genericapp.GenericApp $((100*1024*1024)) 5000
}

function build_ni_app {
	cd build
	$JAVA_HOME/bin/native-image \
		--no-fallback \
		-cp libs/genericapp-1.0-all.jar\
		-DGraalVisorGuest=true \
		-Dcom.oracle.svm.graalvisor.libraryPath=resources/main/com.oracle.svm.graalvisor.headers \
		--initialize-at-run-time=com.oracle.svm.graalvisor.utils.JsonUtils \
		-H:+ReportExceptionStackTraces \
		com.genericapp.GenericApp
}

function build_graalvisor_app {
	cd build
	$JAVA_HOME/bin/native-image \
		--no-fallback \
		-cp libs/genericapp-1.0-all.jar\
		-DGraalVisorGuest=true \
		-Dcom.oracle.svm.graalvisor.libraryPath=resources/main/com.oracle.svm.graalvisor.headers \
		--initialize-at-run-time=com.oracle.svm.graalvisor.utils.JsonUtils \
		-H:ConfigurationFileDirectories=../ni-agent-config \
		-H:+ReportExceptionStackTraces \
		--shared \
		-H:Name=libgenericapp
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
#run_app
#build_ni_app
build_graalvisor_app

echo BENCHMARK_PATH=$(DIR)/build/libs/genericapp-1.0.jar
