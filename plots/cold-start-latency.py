#!/usr/bin/env python

import matplotlib
import matplotlib.pyplot as plt
import numpy as np

results = '../results/experiment/coldstart/java'

# Request latency, which may include setting up a sandbox.
def read_request_latency(path):
    with open(results + '/' + path + '/app.log') as file:
        for line in file:
            if 'Time taken' in line:
                return float(line.split()[2])

# Backend startup latency, does not include initialization latency.
def read_backend_startup_latency(path):
    with open(results + '/' + path + '/lambda.log') as file:
        for line in file:
            if 'Graalvisor boot time' in line:
                return float(line.split()[3]) * 1000

# Backend restore latency.
def read_backend_restore_latency(path):
    with open(results + '/' + path + '/backend.log') as file:
        for line in file:
            if 'Restoring' in line and 'done' in line:
                return float(line.split()[4])

# Sandbox startup latency.
def read_sandbox_startup_latency(path):
    with open(results + '/' + path + '/lambda.log') as file:
        for line in file:
            if 'Creating context' in line:
                return float(line.split()[9]) * 1000

# Sandbox restore latency.
def read_sandbox_restore_latency(path):
    with open(results + '/' + path + '/lambda.log') as file:
        for line in file:
            if 'restore took' in line:
                return float(line.split()[2])

# Backend initialization latency, until it is ready to receive requests.
def read_initialization_latency(path):
    with open(results + '/' + path + '/backend.log') as file:
        for line in file:
            if 'Waiting for' in line and "done" in line:
                return float(line.split()[8])

# Input files for each type of virtualization backend.
inputs = {}
inputs['Firecracker']      = 'gv-py-hello-world-vm-context-test-1-1-2048/1'
inputs['NITF']             = 'gv-py-hello-world-svm-context-test-1-1-2048/1'
# VM, Container, and NITF use a Sandbox on top of it.
inputs['Sandbox']          = inputs['NITF']
inputs['Firecracker C/R']  = 'gv-py-hello-world-vm-snapshot-context-test-1-1-2048/1'
inputs['NITF C/R (CRIU)']  = 'gv-py-hello-world-svm-snapshot-context-test-1-1-2048/1'

# Backend startup latencies.
startup = {}
startup['Firecracker']      = read_backend_startup_latency(inputs['Firecracker'])
startup['NITF']             = read_backend_startup_latency(inputs['NITF'])
# A sandbox does not require any backend startup.
startup['Sandbox']          = read_sandbox_startup_latency(inputs['Sandbox'])
startup['Firecracker C/R']  = read_backend_restore_latency(inputs['Firecracker C/R'])
startup['NITF C/R (CRIU)']  = read_backend_restore_latency(inputs['NITF C/R (CRIU)'])

# Backend ready latencies (includes sandbox startup).
ready = {}
ready['Firecracker']      = startup['Firecracker'] + startup['Sandbox']
ready['NITF']             = startup['NITF'] + startup['Sandbox']
ready['Sandbox']          = startup['Sandbox']
ready['Firecracker C/R']  = startup['Firecracker C/R']
ready['NITF C/R (CRIU)']  = startup['NITF C/R (CRIU)']

# Request latencies after backend starts accepting connections (may include sandbox setup).
request = {}
request['Firecracker']     = read_request_latency(inputs['Firecracker']) - startup['Sandbox']
request['NITF']            = read_request_latency(inputs['NITF']) - startup['Sandbox']
request['Sandbox']         = read_request_latency(inputs['Sandbox']) - startup['Sandbox']
request['Firecracker C/R'] = read_request_latency(inputs['Firecracker C/R'])
request['NITF C/R (CRIU)'] = read_request_latency(inputs['NITF C/R (CRIU)'])

print('Request latency in us (Vm and NITF include sandbox startup):')
print(request)
print('Startup latency in us')
print(startup)

del inputs['Sandbox']
del startup['Sandbox']
del ready['Sandbox']
del request['Sandbox']

# TODO - extract rss?

x = np.arange(len(inputs.keys()))
requests = list(request.values())
readies  = list(ready.values())
startups = list(startup.values())

# From us to ms
requests = [x / 1000 for x in requests]
readies = [x / 1000 for x in readies]
startups = [x / 1000 for x in startups]

plt.rcParams.update({'font.size': 12})
fig, ax = plt.subplots()
ax.bar(x, [x + y for x, y in zip(readies, requests)] ,  label='Request', alpha=0.75)
ax.bar(x, readies,  label='Truffle Context', alpha=0.75)
ax.bar(x, startups, label = 'Startup', alpha=0.75)

ax.set_ylabel('Cold Start Latency (ms)')
ax.set_xticks(x, inputs.keys())
ax.set_axisbelow(True)
plt.grid(axis = 'y', linestyle = '--', linewidth = 0.25)
plt.xticks(rotation = 35)

# Uncomment to hide xtics.
#plt.tick_params(
#    axis='x',          # changes apply to the x-axis
#    which='both',      # both major and minor ticks are affected
#    bottom=False,      # ticks along the bottom edge are off
#    top=False,         # ticks along the top edge are off
#    labelbottom=False) # labels along the bottom edge are off

ax.set_yscale('log')
#ax.set_ylim(ymin=0.1, ymax=100000)
#ax.set_xlim(xmin=-.25, xmax=14.7)
fig.set_figwidth(15)
fig.set_figheight(3)

ax.legend(ncol=5, loc='upper right')
plt.savefig("cold-start-latency.pdf", bbox_inches='tight')
plt.savefig("cold-start-latency.png", bbox_inches='tight')
