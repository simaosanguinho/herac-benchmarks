#!/bin/bash

if [ ! -f build/demoisolatecomms ]
then
	echo "build files missing, rebuilding"
	./build.sh
fi

cd build

set -e;

./demoisolatecomms --server $@ &
serverpid=$!
echo "server started, pid: $serverpid"

sleep 1

./demoisolatecomms --client $@ &
clientpid=$!
echo "client started, pid: $clientpid"

wait
