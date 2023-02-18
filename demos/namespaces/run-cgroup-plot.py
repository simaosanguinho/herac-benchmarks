#!/usr/bin/python3

import numpy
import matplotlib.pyplot as plt

creation_mean = numpy.loadtxt('results-cgroup/experiment-creation-mean.dat')
creation_std  = numpy.loadtxt('results-cgroup/experiment-creation-std.dat')
setup_mean    = numpy.loadtxt('results-cgroup/experiment-setup-mean.dat')
setup_std     = numpy.loadtxt('results-cgroup/experiment-setup-std.dat')
adding_mean   = numpy.loadtxt('results-cgroup/experiment-adding-mean.dat')
adding_std    = numpy.loadtxt('results-cgroup/experiment-adding-std.dat')
removing_mean = numpy.loadtxt('results-cgroup/experiment-removing-mean.dat')
removing_std  = numpy.loadtxt('results-cgroup/experiment-removing-std.dat')
labels        = numpy.loadtxt('results-cgroup/experiment-procs.dat', dtype='str')

plt.bar(labels, creation_mean, label='Creation')
bottom = creation_mean
plt.bar(labels, setup_mean, label='Setup', bottom=bottom)
bottom += setup_mean
plt.bar(labels, adding_mean, label='Adding', bottom=bottom)
bottom += adding_mean
plt.bar(labels, removing_mean, label='Removing', bottom=bottom)

plt.ylim(ymin=0)
plt.legend()
plt.xlabel('Concurrent invocations')
plt.ylabel('Time (us)')
plt.savefig('run-cgroup.pdf')
