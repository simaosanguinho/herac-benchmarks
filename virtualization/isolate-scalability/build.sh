#!/bin/bash

if [ -z "$JAVA_HOME" ]
then
        echo "JAVA_HOME is not set. Recommended JVM: graalvm-ee-java11-22.1.0"
fi

export GRAAL_JAR=/home/$USER/.m2/repository/org/graalvm/sdk/graal-sdk/21.2.0/graal-sdk-21.2.0.jar

	#-g \
$JAVA_HOME/bin/javac -cp $GRAAL_JAR:. IsolateScalabilityTest.java
$JAVA_HOME/bin/native-image \
	-H:ReservedAuxiliaryImageBytes=0 \
	-H:AlignedHeapChunkSize=65536 \
	-H:-UseCompressedReferences \
	-R:MaxHeapSize=16k \
	-R:MinHeapSize=16k \
	-cp $GRAAL_JAR:. IsolateScalabilityTest
