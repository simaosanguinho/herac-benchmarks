#!/bin/bash

function DIR {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

if [[ -z "${ARGO_HOME}" ]]; then
	echo "ARGO_HOME is not defined. Existing..."
	exit 1
fi

function build_graalvisor_host {
	source $ARGO_HOME/lambda-manager/src/scripts/environment.sh
	cd build
	$JAVA_HOME/bin/native-image \
		-H:+ReportExceptionStackTraces \
		--no-fallback \
		-cp libs/virtualization-benchmarks-1.0-all.jar \
		-DGraalVisorHost \
		-Dcom.oracle.svm.graalvisor.libraryPath=resources/main/com.oracle.svm.graalvisor.headers \
		--initialize-at-run-time=com.oracle.svm.graalvisor.utils.JsonUtils \
                GraalvisorHostIsolateBenchmark \
                graalvisorhost
}

./gradlew clean shadowJar assemble

build_graalvisor_host
