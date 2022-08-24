#!/bin/bash

rm *.dat &> /dev/null
for isolates in 1 2 4 8 16 32 64 128 256 512 1024
do
	for attempt in 1 2 3 4 5
	do
		echo "Running with $isolates attempt $attempt..."
		/bin/time -v ./isolatescalabilitytest $isolates &> run-$isolates-$attempt.log
		echo "Running with $isolates attempt $attempt... done!"
		sleep 1
	done
	cat run-$isolates-*.log | grep took | awk '{print $5}' >> latency-$isolates.dat
	cat run-$isolates-*.log | grep "Maximum resident set size" | awk '{print $6}' >> memory-$isolates.dat

done
