#!/usr/bin/python3

import matplotlib
from matplotlib import pyplot as plt

# Isolate, Fork, Snapshot, Graalvisor, CPython, V8, JVM, Firacracker, Docker, Qemu
x =    [0.48, 5.0, 16.61, 14.74, 8.72, 36.56, 38.32, 63.54, 46.95, 118.54] # Memory
y =    [0.25, 0.4, 01.94, 05.00, 13.1, 40.80, 26.90, 166.7, 257.1, 241.70] # Latency

matplotlib.rcParams.update({'font.size': 16})
plt.rcParams["figure.figsize"] = (8, 5.5)

plt.xlabel('Memory Footprint (MB)')
plt.ylabel('Sartup Latency (ms)')

plt.xlim(0.11, 1000)
plt.ylim(0.11, 1000)

plt.yscale('log', base=10)
plt.xscale('log', base=10)

plt.grid()

plt.plot(x, y, "o", markersize=10, markerfacecolor="blue")

plt.annotate('Graalvisor Isolate', xy=(x[0] + .125, y[0] - 0.1))
plt.annotate('Graalvisor Fork', xy=(x[1] + 1, y[1]))
plt.annotate('Firecracker Snapshot', xy=(x[2] + 4.5, y[2]))
plt.annotate('Graalvisor', xy=(x[3] + 4.5, y[3]))
plt.annotate('CPython', xy=(x[4] - 7, y[4] - 2))
plt.annotate('NodeJS', xy=(x[5] - 27.5, y[5] - 2.5))
plt.annotate('JVM', xy=(x[6] + 15, y[6] - 2.5))
plt.annotate('Firecracker', xy=(x[7] + 15, y[7] - 75))
plt.annotate("Docker", xy=(x[8] - 35, y[8] + 20))
plt.annotate("QEMU", xy=(x[9] + 15, y[9] + 30))

#plt.axvline(x=125)
#plt.axhline(y=750)
#plt.fill_betweenx([0, 200], [0, 0], [100, 200])
#plt.fill_between([100, 200], [1, 1], [1000, 1000])

plt.savefig('virtualization-performance.pdf')
plt.savefig('virtualization-performance.png')
#plt.show()
