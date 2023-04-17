#!/usr/bin/python

import matplotlib
import matplotlib.pyplot as plt
import numpy as np

gv      = np.loadtxt("gv_dc_throughput.txt")
gv_fork = np.loadtxt("gv_fork_throughput.txt")
cr      = np.loadtxt("cr_throughput.txt")
ph      = np.loadtxt("ph_throughput.txt")

matplotlib.rcParams.update({'font.size': 16})
plt.rcParams["figure.figsize"] = (10, 4)
plt.plot(gv,      linestyle = ":",  linewidth = 3, label = "Graalvisor")
plt.plot(gv_fork, linestyle = "-",  linewidth = 3, label = "Forking")
plt.plot(ph,      linestyle = "--", linewidth = 3, label = "Photons")
plt.plot(cr,      linestyle = "-.", linewidth = 3, label = "OpenWhisk")
plt.xlabel("Time (s)")
plt.ylabel("Throughput (ops/s)")
plt.grid()
plt.legend(ncol=4, loc='upper right')
plt.tight_layout()
plt.savefig("azure-replay-throughput.pdf")
plt.savefig("azure-replay-throughput.png")
plt.show()
