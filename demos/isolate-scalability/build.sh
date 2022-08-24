#!/bin/bash

export JAVA_HOME=/home/rbruno/software/graalvm-ee-java11-22.1.0/
export GRAAL_JAR=/home/rbruno/.m2/repository/org/graalvm/sdk/graal-sdk/21.2.0/graal-sdk-21.2.0.jar

$JAVA_HOME/bin/javac -cp $GRAAL_JAR:. IsolateScalabilityTest.java
$JAVA_HOME/bin/native-image \
	-H:ReservedAuxiliaryImageBytes=0 \
	-H:+UseCompressedReferences \
	-R:MaxHeapSize=16k \
	-R:MinHeapSize=16k \
	-cp $GRAAL_JAR:. IsolateScalabilityTest
