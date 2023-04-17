#!/usr/bin/python

import matplotlib
import matplotlib.pyplot as plt
import numpy as np

# Loading memory and converting from MBs to GBs
gv      = np.loadtxt("gv_dc_footprint.txt")   / 1000
gv_fork = np.loadtxt("gv_fork_footprint.txt") / 1000
cr      = np.loadtxt("cr_footprint.txt")      / 1000
ph      = np.loadtxt("ph_footprint.txt")      / 1000

matplotlib.rcParams.update({'font.size': 16})
plt.rcParams["figure.figsize"] = (10, 4)
plt.plot(gv,      linestyle = ":",  linewidth = 3, label = "Graalvisor")
plt.plot(gv_fork, linestyle = "-",  linewidth = 3, label = "Forking")
plt.plot(ph,      linestyle = "--", linewidth = 3, label = "Photons")
plt.plot(cr,      linestyle = "-.", linewidth = 3, label = "OpenWhisk")
plt.xlabel("Time (s)")
plt.ylabel("Memory (GBs)")
plt.grid()
plt.legend(ncol=2, loc='lower right')
plt.tight_layout()
plt.savefig("azure-replay-memory.pdf")
plt.savefig("azure-replay-memory.png")
plt.show()
