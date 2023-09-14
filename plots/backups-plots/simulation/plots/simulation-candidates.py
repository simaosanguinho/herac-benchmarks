#!/usr/bin/python

import results
import matplotlib
import matplotlib.pyplot as plt
import numpy as np


RESULTS_FILE = "../results/simulation_d02_keepalive_10min_duration_30min.txt"
width = 1.0


x = results.read_column(RESULTS_FILE, 1)
yRunningFunctions = np.array(results.read_column(RESULTS_FILE, 12))
yOptimizedRunningFunctions = np.array(results.read_column(RESULTS_FILE, 29))

yUnoptimizedRunningFunctions = yRunningFunctions - yOptimizedRunningFunctions


first = x[0]
x = [elem - first for elem in x]
# Convert from ms to sec
x = [elem / 1000 for elem in x]

plt.rcParams.update({'font.size': 24, 'text.usetex': True, 'font.family': 'sans-serif', 'font.sans-serif': 'Helvetica'})
fig, ax = plt.subplots()

bottom = np.zeros(len(x))
ax.bar(x, yOptimizedRunningFunctions, width=width, label="Optimized", bottom=bottom)
bottom += yOptimizedRunningFunctions
ax.bar(x, yUnoptimizedRunningFunctions, width=width, label="Unoptimized", bottom=bottom)

ax.set_xlabel("Time (s)")
ax.set_ylabel("Number of running functions")

xticks = np.arange(0, 1801, 600)
ax.set_xticks(xticks)
ax.grid()

# ax.set_yscale('log')
ax.set_ylim(ymin=0)
ax.set_xlim(xmin=0, xmax=1800)
fig.set_figwidth(10)
fig.set_figheight(5)

ax.legend(ncol=5, loc='upper center')
plt.savefig("simulation-candidates.pdf", bbox_inches='tight')
plt.savefig("simulation-candidates.png", bbox_inches='tight')
plt.show()
