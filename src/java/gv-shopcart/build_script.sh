#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

function run_hotspot {
        $JAVA_HOME/bin/java \
                -cp target/shopcart-0.3.6.jar \
                micronaut.benchmark.shopcart.Application
}

function build_ni {
	cd target
	$JAVA_HOME/bin/native-image \
		--no-fallback \
		-cp shopcart-0.3.6.jar:$ARGO_HOME/graalvisor-lib/build/libs/graalvisor-lib-1.0-guest.jar \
		-DGraalVisorGuest=true \
		-Dcom.oracle.svm.graalvisor.libraryPath=$ARGO_HOME/graalvisor-lib/build/resources/main/com.oracle.svm.graalvisor.headers \
		--initialize-at-run-time=com.oracle.svm.graalvisor.utils.JsonUtils \
		-H:ConfigurationFileDirectories=../ni-agent-config \
		-H:+ReportExceptionStackTraces \
		$NI_BIN_OPTS \
		-H:Name=libshopcart
}

function build_ni_standalone {
	NI_BIN_OPTS="micronaut.benchmark.shopcart.Application"
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

mvn clean package

TARGET=$1
if [ ! -z "$TARGET" ]
then
        $TARGET
	exit 0
else
	read -p "Run benchmark on hotspot (y or Y, everything else as no)? " -n 1 -r
        echo # move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
                run_hotspot
                exit 0
        fi
	read -p "Build standalone Native Image (y or Y, everything else as no)? " -n 1 -r
        echo # move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
                build_ni_standalone
                exit 0
        fi
	read -p "Build shared library Native Image (y or Y, everything else as no)? " -n 1 -r
        echo # move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
                build_ni_sharedlibrary
                exit 0
        fi
fi
