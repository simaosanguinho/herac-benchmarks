#!/bin/bash

if [ ! -f build/demoisolatecomms ]
then
	echo "build files missing, rebuilding"
	./build.sh
fi

cd build
timestamp=$(date +%s)
store_dir=../logs/$timestamp
mkdir -p $store_dir

echo $JAVA_HOME

set -e;


echo "Running on HotSpot"

$JAVA_HOME/bin/java \
	-jar libs/demo-ni-isolate-comms-1.0-all.jar \
	--server $@ \
	| tee $store_dir/"$timestamp"_hotspot_server.log &

sleep 1

$JAVA_HOME/bin/java \
	-jar libs/demo-ni-isolate-comms-1.0-all.jar \
	--client $@ \
	| tee $store_dir/"$timestamp"_hotspot_client.log &

wait

echo "Running on SVM"

./demoisolatecomms \
	--server $@ \
	| tee $store_dir/"$timestamp"_svm_server.log &

sleep 1

./demoisolatecomms \
	--client $@ \
	| tee $store_dir/"$timestamp"_svm_client.log &

wait
