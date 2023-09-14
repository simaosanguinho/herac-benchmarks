#!/usr/bin/python

import results
import matplotlib
import matplotlib.pyplot as plt
import numpy as np


RESULTS_FILE_UNOPTIMIZED = "../results/simulation_d02_keepalive_10min_duration_30min_unoptimized.txt"
RESULTS_FILE_OPTIMIZED = "../results/simulation_d02_keepalive_10min_duration_30min.txt"
width = 1.0


x = results.read_column(RESULTS_FILE_OPTIMIZED, 1)
yRunningFootprint = np.array(results.read_column(RESULTS_FILE_UNOPTIMIZED, 16))        / 1024
yRunningFootprintOptimized = np.array(results.read_column(RESULTS_FILE_OPTIMIZED, 16)) / 1024


first = x[0]
x = [elem - first for elem in x]
# Convert from ms to sec
x = [elem / 1000 for elem in x]

plt.rcParams.update({'font.size': 22, 'text.usetex': True, 'font.family': 'sans-serif', 'font.sans-serif': 'Helvetica'})
fig, ax = plt.subplots()
ax.set_xlabel("Time (s)")
ax.set_ylabel("Memory (GB)")

ax.plot(x, yRunningFootprintOptimized, linewidth=3, linestyle="--", label='With CloudJIT')
ax.plot(x, yRunningFootprint,          linewidth=3, label='Without CloudJIT')

xticks = np.arange(0, 1801, 600)
ax.set_xticks(xticks)
ax.grid()

# plt.yscale('log', base=10)
ax.set_ylim(ymin=0, ymax=1700)
ax.set_xlim(xmin=0, xmax=1800)
fig.set_figwidth(10)
fig.set_figheight(5)

plt.legend(ncol=5, loc='upper center')
plt.savefig("simulation-footprint.pdf", bbox_inches='tight')
plt.savefig("simulation-footprint.png", bbox_inches='tight')
plt.show()
