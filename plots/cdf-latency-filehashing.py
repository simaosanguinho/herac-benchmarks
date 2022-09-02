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

fig = plt.figure()
plt.plot(x_cr, y_cr, marker='o', label='OpenWisk JVM')
plt.plot(x_gv, y_gv, marker='x', label='Graalvisor')
plt.ylim(ymin=0, ymax=1)
plt.xlim(xmin=0)
plt.ylabel('Cumulative Distribution Function')
plt.xlabel('Request Latency (us)')
plt.legend()

# ../results/java/gv-file-hashing-niuk/lambda.rss
# ../results/java/cr-file-hashing/lambda.rss
y = [179380, 223460 ]
ax1 = fig.add_axes([0.55, 0.3, 0.3, 0.4])
ax1.set_ylabel('Memory Footprint (KBs)')
ax1.bar(['GV Unikernel', 'JVM VM'], y, width = .4)

plt.show()
plt.savefig("cdf-latency-filehashing.pdf")
