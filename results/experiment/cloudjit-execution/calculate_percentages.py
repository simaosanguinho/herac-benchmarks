#!/usr/bin/python

import matplotlib.pyplot as plt
import numpy as np

# ---------------- footprint ----------------

hs = np.loadtxt("hotspot_footprint.txt")
pl = np.loadtxt("pipeline_footprint.txt")

def stretch(data):
    result = []
    i = 1
    while i < len(data):
        result.append(data[i])
        if i % 8 == 0 and i + 1 < len(data):
            result.append(np.mean([data[i], data[i+1]]))
        i += 1
    return result


hs = np.loadtxt("raw_hotspot_footprint.txt")
pl = np.loadtxt("raw_pipeline_footprint.txt")

hs = hs[600:1400]
pl = pl[600:1400]
kernel_size = 50
kernel = np.ones(kernel_size) / kernel_size
hs = np.convolve(hs, kernel, mode='same')
pl = np.convolve(pl, kernel, mode='same')
# Stretch data to fit 1800 seconds
hs = np.array(stretch(hs))
pl = np.array(stretch(pl))

diff = hs - pl
percentages = diff * 100 / hs

print("Memory footprint on average got improved by:")
print(percentages.mean())

# ---------------- running functions ----------------

def group(data):
    i = 0
    res_data = []
    while i < len(data):
        gv_functions = set()
        all_functions = set()
        curr_ts = data[i][0]
        end_window_ts = curr_ts + 10000
        while i < len(data) and data[i][0] < end_window_ts:
            if data[i][2] == "GRAALVISOR":
                gv_functions.add(data[i][1])
            all_functions.add(data[i][1])
            i += 1
        res_data.append((len(all_functions), len(gv_functions)))
    return res_data


f = open("raw_pipeline_lambda_manager.log", "r")
lines = f.readlines()
lines = [l for l in lines if "FINE Time" in l]
lines = lines[:-5]
data = [(int(x.split(' ')[1][1:-1]), x.split(' ')[5][14:-1], x.split(' ')[6][5:-1]) for x in lines]
data = group(data)
all_functions = np.array([x[0] for x in data])
gv_functions = np.array([x[1] for x in data])

all_functions = all_functions[60:]
gv_functions = gv_functions[60:]

percentages = gv_functions * 100 / all_functions

print("Average percentage of optimized functions:")
print(percentages.mean())

# ---------------- cold starts ----------------

def group(data):
    i = 0
    res_data = []
    while i < len(data):
        all_count = 0
        gv_count = 0
        curr_ts = data[i][0]
        end_window_ts = curr_ts + 10000
        while i < len(data) and data[i][0] < end_window_ts:
            if data[i][1] == "GRAALVISOR":
                gv_count += 1
            all_count += 1
            i += 1
        res_data.append((all_count, gv_count))
    return res_data


f = open("raw_pipeline_lambda_manager.log", "r")
lines = f.readlines()
lines = [l for l in lines if "cold start" in l]
lines = lines[:-5]
data = [(int(x.split(' ')[1][1:-1]), x.split(' ')[6][5:-1]) for x in lines]
data = group(data)
all_coldstarts = np.array([x[0] for x in data])
gv_coldstarts = np.array([x[1] for x in data])

all_coldstarts = all_coldstarts[60:]
gv_coldstarts = gv_coldstarts[60:]

percentages = gv_coldstarts * 100 / all_coldstarts

print("Average percentage of optimized cold starts:")
print(percentages.mean())
