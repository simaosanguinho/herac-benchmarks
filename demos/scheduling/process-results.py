#!/usr/bin/python

import os
import statistics
import numpy
import matplotlib.pyplot as plt

results_dir = os.path.dirname(os.path.realpath(__file__)) + '/results'
results = {}

def load_results(exp_number):
    experiment_results = []
    for filename in os.listdir(results_dir + '/' + str(exp_number)):
        with open(results_dir + '/' + str(exp_number) + '/' + filename) as file:
            for line in file:
                if "result" not in line:
                    continue
                # Line example: {"result":"{}","process time (us)":1354355}
                element = float(line.rstrip().split(":")[2].replace('}', ''))
                # Convert from us to ms.
                element = element / 1000
                # Remove sleep 1 second latency
                element = element - 1000 # TODO - fixme?
                experiment_results.append(element)
    results[exp_number] = experiment_results

# Experiments (x-axis)
experiments = [int(x) for x in os.listdir(results_dir)]
experiments.sort()

for experiment in experiments:
    load_results(experiment)


# Average values (y-axis)
averages = [statistics.mean(results[experiment]) for experiment in experiments]
plt.plot(experiments, averages, label='Mean')

# 90th percentile (y-axis)
p90 = [numpy.percentile(numpy.array(results[experiment]), 90) for experiment in experiments]
plt.plot(experiments, p90, label='P90')

# 99th percentile (y-axis)
p99 = [numpy.percentile(numpy.array(results[experiment]), 99) for experiment in experiments]
plt.plot(experiments, p99, label='P99')

# 99th percentile (y-axis)
p999 = [numpy.percentile(numpy.array(results[experiment]), 99.9) for experiment in experiments]
plt.plot(experiments, p999, label='P99.9')

plt.ylim(0)
plt.xlabel('Concurrent sandboxes')
plt.ylabel('Overhead (latency in ms)')
plt.legend()
plt.savefig("scheduling.png", bbox_inches='tight')