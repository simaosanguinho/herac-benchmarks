#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

function run_hotspot {
        $JAVA_HOME/bin/java \
		-Dcom.oracle.svm.graalvisor.polyglotengine.language=js \
		-Dcom.oracle.svm.graalvisor.polyglotengine.entrypoint=main \
		-Dcom.oracle.svm.graalvisor.polyglotengine.source=$DIR/src/main/javascript/main.js \
                -cp build/libs/uploader-1.0-all.jar \
                com.uploader.Uploader
}

function build_ni {
	cd build
	$JAVA_HOME/bin/native-image \
		--no-fallback \
		--enable-url-protocols=http \
		-cp libs/uploader-1.0-all.jar \
		-DGraalVisorGuest=true \
		-Dcom.oracle.svm.graalvisor.libraryPath=resources/main/com.oracle.svm.graalvisor.headers \
		-Dcom.oracle.svm.graalvisor.polyglotengine.language=js \
		-Dcom.oracle.svm.graalvisor.polyglotengine.entrypoint=main \
		-Dcom.oracle.svm.graalvisor.polyglotengine.source=$DIR/src/main/javascript/main.js \
		--initialize-at-build-time=com.uploader.Uploader \
		--initialize-at-run-time=com.oracle.svm.graalvisor.utils.JsonUtils \
		-H:ConfigurationFileDirectories=../ni-agent-config \
		--language:js \
		-H:+ReportExceptionStackTraces \
		$NI_BIN_OPTS \
		-H:Name=libuploader
}

function build_ni_standalone {
	NI_BIN_OPTS="com.uploader.Uploader"
	build_ni
}

function build_ni_sharedlibrary {
	NI_BIN_OPTS="--shared"
	build_ni
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

#run_hotspot
#build_ni_standalone
build_ni_sharedlibrary

echo BENCHMARK_PATH=$DIR/build/libs/uploader-1.0.jar
