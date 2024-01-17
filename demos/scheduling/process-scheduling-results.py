#!/usr/bin/python

import os
import statistics
import numpy
import matplotlib.pyplot as plt

results_dir = os.path.dirname(os.path.realpath(__file__)) + '/results'
sched = []
wait = []

def load_results(exp_number):
    with open(results_dir + '/' + str(exp_number) + '/sched.time') as file:
        sched.append(float(file.read().replace('\n', '')))
    with open(results_dir + '/' + str(exp_number) + '/wait.time') as file:
        wait.append(float(file.read().replace('\n', '')))

# Experiments (x-axis)
experiments = [int(x) for x in os.listdir(results_dir)]
experiments.sort()

for experiment in experiments:
    load_results(experiment)

fig, axs = plt.subplots(2)
axs[0].plot(experiments, sched)
axs[0].set_title('Schedule Time')
axs[0].set_ylabel('Latency in ms')
axs[0].set_ylim(0)
axs[1].plot(experiments, wait)
axs[1].set_title('Wait Time (after deducting sleep duration)')
axs[1].set_ylabel('Latency in ms')
axs[1].set_ylim(0)
axs[1].set_xlabel('Concurrent sandboxes')
fig.tight_layout()
#plt.ylabel('Latency in ms')
plt.savefig("scheduling-latency.png")