#!/bin/bash

function build_graalvisor_app {
	cd target
	$JAVA_HOME/bin/native-image \
		--no-fallback \
		-cp shopcart-0.3.6.jar:$ARGO_HOME/graalvisor-lib/build/libs/graalvisor-lib-1.0-guest.jar \
		-DGraalVisorGuest=true \
		-Dcom.oracle.svm.graalvisor.libraryPath=$ARGO_HOME/graalvisor-lib/build/resources/main/com.oracle.svm.graalvisor.headers \
		--initialize-at-run-time=com.oracle.svm.graalvisor.utils.JsonUtils \
		-H:ConfigurationFileDirectories=../ni-agent-config \
		-H:+ReportExceptionStackTraces \
		--shared \
		-H:Name=libshopcart
}

mvn clean package
build_graalvisor_app
