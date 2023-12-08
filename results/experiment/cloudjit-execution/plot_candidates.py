import matplotlib
import matplotlib.pyplot as plt
import numpy as np


def group(data):
    i = 0
    res_data = []
    while i < len(data):
        gv_functions = set()
        hs_functions = set()
        curr_ts = data[i][0]
        end_window_ts = curr_ts + 10000
        while i < len(data) and data[i][0] < end_window_ts:
            if data[i][2] == "GRAALVISOR":
                gv_functions.add(data[i][1])
            elif "HOTSPOT" in data[i][2]:
                hs_functions.add(data[i][1])
            i += 1
        res_data.append((curr_ts, len(hs_functions), len(gv_functions)))
    return res_data


f = open("raw_pipeline_lambda_manager.log", "r")
lines = f.readlines()

lines = [l for l in lines if "FINE Time" in l]
lines = lines[:-5]

data = [(int(x.split(' ')[1][1:-1]), x.split(' ')[5][14:-1], x.split(' ')[6][5:-1]) for x in lines]

data = group(data)

timestamps = np.array([x[0] for x in data])
hs_functions = np.array([x[1] for x in data])
gv_functions = np.array([x[2] for x in data])

first_ts = timestamps[0]
timestamps = timestamps - first_ts
timestamps = [int(x / 1000) for x in timestamps]

for i in range(1, len(timestamps)):
    if timestamps[i] - timestamps[i-1] != 10:
        timestamps[i] = timestamps[i-1] + 10
print(timestamps)

plt.rcParams.update({'font.size': 24, 'text.usetex': True, 'font.family': 'sans-serif', 'font.sans-serif': 'Helvetica'})
fig, ax = plt.subplots()
width = 10

bottom = np.zeros(len(timestamps))
ax.bar(timestamps, gv_functions, width=width, label="Optimized", bottom=bottom)
bottom += gv_functions
ax.bar(timestamps, hs_functions, width=width, label="Unoptimized", bottom=bottom)

ax.set_xlabel("Time (s)")
ax.set_ylabel("Number of running functions")

xticks = np.arange(0, 1801, 600)
ax.set_xticks(xticks)
ax.grid()

# ax.set_yscale('log')
ax.set_ylim(ymin=0, ymax=100)
ax.set_xlim(xmin=0, xmax=1800)
fig.set_figwidth(10)
fig.set_figheight(5)

ax.legend(ncol=5, loc='upper center')
plt.savefig("candidates.pdf", bbox_inches='tight')
plt.savefig("candidates.png", bbox_inches='tight')
plt.show()
