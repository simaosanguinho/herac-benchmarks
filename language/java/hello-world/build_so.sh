#!/bin/bash

source ../../../../argo/lambda-manager/src/scripts/environment.sh

cd build

$JAVA_HOME/bin/native-image --no-fallback -cp libs/hello-world-1.0-all.jar\
  -DGraalVisorGuest=true \
  -Dcom.oracle.svm.graalvisor.libraryPath=resources/main/com.oracle.svm.graalvisor.headers \
  --initialize-at-run-time=com.oracle.svm.graalvisor.utils.JsonUtils \
  -H:ConfigurationFileDirectories=../ni-agent-config \
  -H:+ReportExceptionStackTraces\
  --shared -H:Name=libhelloworld
