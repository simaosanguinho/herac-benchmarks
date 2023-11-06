#!/usr/bin/python

import os
import statistics
import numpy
import matplotlib.pyplot as plt

results_dir = os.path.dirname(os.path.realpath(__file__)) + '/results'
results = {}

def load_results(exp_number):
    experiment_results = []
    for filename in os.listdir(results_dir + '/' + exp_number):
        with open(results_dir + '/' + exp_number + '/' + filename) as file:
            for line in file:
                if "result" not in line:
                    continue
                # Line example: {"result":"{}","process time (us)":1354355}
                element = float(line.rstrip().split(":")[2].replace('}', ''))
                # Convert from us to ms.
                element = element / 1000
                experiment_results.append(element)
    results[exp_number] = experiment_results

for experiment in os.listdir(results_dir):
    load_results(experiment)

# Experiments (x-axis)
experiments = list(results.keys())
experiments.sort()

# Average values (y-axis)
averages = [statistics.mean(results[experiment]) for experiment in experiments]
plt.plot(experiments, averages, label='Mean')

# 90th percentile (y-axis)
p90 = [numpy.percentile(numpy.array(results[experiment]), 90) for experiment in experiments]
plt.plot(experiments, p90, label='P90')

# 99th percentile (y-axis)
p99 = [numpy.percentile(numpy.array(results[experiment]), 99) for experiment in experiments]
plt.plot(experiments, p99, label='P99')

plt.xlabel('Concurrent sandboxes')
plt.ylabel('Latency (ms)')
plt.legend()
plt.savefig("scheduling.png", bbox_inches='tight')