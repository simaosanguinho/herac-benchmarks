#!/bin/bash

for language in language/*
do
	for benchmark in $language/*
	do
		if [ -f "$benchmark/build_script.sh" ]; then
			echo "$benchmark/build_script.sh exists, building..."
			cd $benchmark
			bash build_script.sh
			cd - &> /dev/null
			echo "$benchmark/build_script.sh exists, building... done!"
		else
			echo "$benchmark/build_script.sh DOES NOT exist, skipping."
		fi
	done
done
