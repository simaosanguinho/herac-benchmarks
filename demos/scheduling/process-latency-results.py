#!/usr/bin/python

import os
import statistics
import numpy
import matplotlib.pyplot as plt

results_dir = os.path.dirname(os.path.realpath(__file__)) + '/results'
results = {}

def load_results(exp_number):
    experiment_results = []
    errors = 0
    with open(results_dir + '/' + str(exp_number) + '/worker.load') as file:
        for line in file:
            try:
                if "result" not in line:
                    continue
                # Line example: {"result":"{}","process time (us)":1354355}
                element = float(line.rstrip().split(":")[2].replace('}', ''))
                # Convert from us to ms.
                element = element / 1000
                # Remove sleep 1 second latency
                element = element - 100 # TODO - fixme?
                experiment_results.append(element)
            except (ValueError, IndexError):
                errors = errors + 1
    results[exp_number] = experiment_results
    print("Found {} errors in experiment {}.".format(errors, exp_number))

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

# 999th percentile (y-axis)
#p999 = [numpy.percentile(numpy.array(results[experiment]), 99.9) for experiment in experiments]
#plt.plot(experiments, p999, label='P99.9')

plt.ylim(0)
plt.xlabel('Concurrent sandboxes')
plt.ylabel('Overhead (latency in ms)')
plt.legend()
plt.savefig("request-latency.png", bbox_inches='tight')