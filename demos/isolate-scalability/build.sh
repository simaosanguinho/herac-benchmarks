#!/bin/bash

if [[ -z "${ARGO_HOME}" ]]; then
	echo "ARGO_HOME is not defined. Existing..."
	exit 1
fi

./gradlew clean shadowJar assemble
source $ARGO_HOME/lambda-manager/src/scripts/environment.sh
cd build
$JAVA_HOME/bin/native-image \
	-H:ReservedAuxiliaryImageBytes=0 \
	-H:AlignedHeapChunkSize=65536 \
	-H:-UseCompressedReferences \
	-R:MaxHeapSize=16k \
	-R:MinHeapSize=16k \
	-cp libs/virtualization-benchmarks-1.0-all.jar \
	IsolateScalabilityTest \
	isolate-scalability


