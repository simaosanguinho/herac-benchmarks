#!/usr/bin/python

import numpy as np
import matplotlib.pyplot as plt

def read_benchmark_latency(path):
    benchmark_latency = []
    with open(path) as file:
        for line in file:
            if 'Time taken:' in line:
                benchmark_latency.append(int(line.split()[2]))
    return benchmark_latency


cr = read_benchmark_latency('../results/java/cr-file-hashing/app.log')
gv = read_benchmark_latency('../results/java/gv-file-hashing-niuk/app.log')

x_cr = np.sort(cr)
x_gv = np.sort(gv)
  
y_cr = np.arange(len(cr)) / float(len(cr))
y_gv = np.arange(len(gv)) / float(len(gv))
  
plt.plot(x_cr, y_cr, marker='o', label='OpenWisk Java Runtime')
plt.plot(x_gv, y_gv, marker='x', label='Graalvisor')
plt.ylim(ymin=0, ymax=1)
plt.xlim(xmin=0)
plt.ylabel('Cumulative Distribution Function')
plt.xlabel('Request Latency (us)')
plt.legend()
plt.savefig("cdf-latency-filehashing.pdf")
