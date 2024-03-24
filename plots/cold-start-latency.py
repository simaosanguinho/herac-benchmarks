#!/usr/bin/python

import matplotlib
import matplotlib.pyplot as plt
import numpy as np

results = '../results/experiment/coldstart/java'

# Request latency, which may include setting up a sandbox.
def read_request_latency(path):
    lats = []
    with open(results + '/' + path + '/app.log') as file:
        for line in file:
            if 'Time taken' in line:
                lats.append(int(line.split()[2]))
    return lats

# Backend startup latency, does not include initialization latency.
def read_backend_startup_latency(path):
    lats = []
    with open(results + '/' + path + '/lambda.log') as file:
        for line in file:
            if 'Graalvisor boot time' in line:
                lats.append(int(line.split()[3]))
    return lats

# Backend startup latency, does not include initialization latency.
def read_backend_startup_latency(path):
    lats = []
    with open(results + '/' + path + '/lambda.log') as file:
        for line in file:
            if 'Graalvisor boot time' in line:
                lats.append(int(line.split()[3]))
    return lats

# Backend restore latency.
def read_backend_restore_latency(path):
    lats = []
    with open(results + '/' + path + '/backend.log') as file:
        for line in file:
            if 'Restoring' in line and 'done' in line:
                lats.append(int(line.split()[4]))
    return lats

# Sandbox startup latency.
def read_sandbox_startup_latency(path):
    lats = []
    with open(results + '/' + path + '/lambda.log') as file:
        for line in file:
            if 'Creating context' in line:
                lats.append(int(line.split()[9]))
    return lats

# Sandbox restore latency.
def read_sandbox_restore_latency(path):
    lats = []
    with open(results + '/' + path + '/lambda.log') as file:
        for line in file:
            if 'restore took' in line:
                lats.append(int(line.split()[2]))
    return lats

# Backend initialization latency, until it is ready to receive requests.
def read_initialization_latency(path):
    lats = []
    with open(results + '/' + path + '/backend.log') as file:
        for line in file:
            if 'Waiting for' in line and "done" in line:
                lats.append(int(line.split()[8]))
    return lats

# Input files for each type of virtualization backend.
inputs = {}
inputs['VM']            = 'gv-py-hello-world-vm-context-test-3-1-2048/1'
inputs['Container']     = 'gv-py-hello-world-container-context-test-3-1-2048/1'
inputs['NITF']          = 'gv-py-hello-world-svm-context-test-3-1-2048/1'
# VM, Container, and NITF use a Sandbox on top of it.
inputs['Sandbox']       = inputs['NITF']
inputs['VM Snap']       = 'gv-py-hello-world-vm-snapshot-context-test-3-1-2048/1'
inputs['NITF Snap']     = 'gv-py-hello-world-svm-snapshot-context-test-3-1-2048/1'
inputs['Sandbox Snap']  = 'gv-py-hello-world-svm-context-snapshot-test-3-1-2048/1'

# Request latencies after backend starts accepting connections.
requests = {}
requests['VM']              = read_request_latency(inputs['VM'])
requests['Container']       = read_request_latency(inputs['Container'])
requests['NITF']            = read_request_latency(inputs['NITF'])
requests['Sandbox']         = read_request_latency(inputs['Sandbox'])
requests['VM Snap']         = read_request_latency(inputs['VM Snap'])
requests['NITF Snap']       = read_request_latency(inputs['NITF Snap'])
requests['Sandbox Snap']    = read_request_latency(inputs['Sandbox Snap'])

# Backend startup latencies.
startup = {}
startup['VM']               = read_backend_startup_latency(inputs['VM'])
startup['Container']        = read_backend_startup_latency(inputs['Container'])
startup['NITF']             = read_backend_startup_latency(inputs['NITF'])
startup['Sandbox']          = read_sandbox_startup_latency(inputs['Sandbox'])
startup['VM Snap']          = read_backend_restore_latency(inputs['VM Snap'])
startup['NITF Snap']        = read_backend_restore_latency(inputs['NITF Snap'])
startup['Sandbox Snap']     = read_sandbox_restore_latency(inputs['Sandbox Snap'])

# Backend initialization latencies.
initialization = {}
initialization['VM']               = read_initialization_latency(inputs['VM'])
initialization['Container']        = read_initialization_latency(inputs['Container'])
initialization['NITF']             = read_initialization_latency(inputs['NITF'])
# Sice sandbox does not require external resources (sockets, etc), it defaults to startup latency.
initialization['Sandbox']          = startup['Sandbox']
initialization['VM Snap']          = read_initialization_latency(inputs['VM Snap'])
initialization['NITF Snap']        = read_initialization_latency(inputs['NITF Snap'])
initialization['Sandbox Snap']     = startup['Sandbox Snap']

print('Requests')
print(requests)
print('Startup')
print(startup)
print('Initialization')
print(initialization)

# TODO - extract request latency for the first
# TODO - extract average request latency for the rest
# TODO - extract rss?
