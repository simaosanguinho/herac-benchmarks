#!/bin/bash

rm -r results &> /dev/null
mkdir results &> /dev/null
rm *.dat      &> /dev/null
for isolates in 1 2 4 8 16 32 64 128
do
	for attempt in 1 2 3 4 5
	do
		echo "Running with $isolates attempt $attempt..."
		/bin/time -v build/graalvisorhost false $isolates ../gv-guest/build/graalvisorguest.so GraalvisorGuestIsolateBenchmark &> results/run-$isolates-$attempt.log
		echo "Running with $isolates attempt $attempt... done!"
		if ! grep -q SubstrateSegfaultHandler "results/run-$isolates-$attempt.log"; then
			cat results/run-$isolates-$attempt.log | grep -v -P '\t' >> results/latency-$isolates.dat
			cat results/run-$isolates-$attempt.log | grep "Maximum resident set size" | awk '{print $6}' >> results/memory-$isolates.dat
		fi
		sleep 1
	done

done
