#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

function run_hotspot {
	rm -rf config-dir
	$JAVA_HOME/bin/java \
		-Djava.awt.headless=true \
		-agentlib:native-image-agent=config-output-dir=config-dir/ \
		-cp build/libs/classify-1.0-all.jar \
		com.classify.Classify
}

function build_ni {
	cd build
	$JAVA_HOME/bin/native-image \
		--no-fallback \
		--enable-url-protocols=http \
		-Djava.awt.headless=true \
		-cp libs/classify-1.0-all.jar \
		--initialize-at-run-time=com.oracle.svm.hydra.utils.JsonUtils \
		-H:ConfigurationFileDirectories=../config-dir \
		-H:+ReportExceptionStackTraces \
		$NI_BIN_OPTS \
		-H:Name=hy-jv-classify
}

function build_ni_standalone {
	NI_BIN_OPTS="com.classify.Classify"
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

# Build hydra lib.
bash $ARGO_HOME/hydra-lib/build.sh

# Move into the script directory.
cd $DIR &> /dev/null

# Build.
./gradlew clean shadowJar assemble

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
