#!/usr/bin/python

import results
import matplotlib
import matplotlib.pyplot as plt
import numpy as np


RESULTS_FILE_UNOPTIMIZED = "../results/simulation_d02_keepalive_10min_duration_30min_unoptimized.txt"
RESULTS_FILE_OPTIMIZED = "../results/simulation_d02_keepalive_10min_duration_30min.txt"

unoptimized = np.array(results.read_column(RESULTS_FILE_UNOPTIMIZED, 16))
optimized = np.array(results.read_column(RESULTS_FILE_OPTIMIZED, 16))

diff = unoptimized - optimized

percentages = diff * 100 / unoptimized


print("Memory footprint on average got improved by:")
print(percentages.mean())
