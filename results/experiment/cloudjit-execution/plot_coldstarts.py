import matplotlib
import matplotlib.pyplot as plt
import numpy as np


def group(data):
    i = 0
    res_data = []
    while i < len(data):
        hs_count = 0
        gv_count = 0
        curr_ts = data[i][0]
        end_window_ts = curr_ts + 10000
        while i < len(data) and data[i][0] < end_window_ts:
            if data[i][1] == "GRAALVISOR":
                gv_count += 1
            elif "HOTSPOT" in data[i][1]:
                hs_count += 1
            i += 1
        res_data.append((curr_ts, hs_count, gv_count))
    return res_data


f = open("raw_pipeline_lambda_manager.log", "r")
lines = f.readlines()

lines = [l for l in lines if "cold start" in l]
lines = lines[:-5]

data = [(int(x.split(' ')[1][1:-1]), x.split(' ')[6][5:-1]) for x in lines]

data = group(data)

timestamps = np.array([x[0] for x in data])
hs_coldstarts = np.array([x[1] for x in data])
gv_coldstarts = np.array([x[2] for x in data])

first_ts = timestamps[0]
timestamps = timestamps - first_ts
timestamps = [int(x / 1000) for x in timestamps]

for i in range(1, len(timestamps)):
    if timestamps[i] % 10 != 0:
        timestamps[i] = timestamps[i] - timestamps[i] % 10
print(timestamps)

plt.rcParams.update({'font.size': 24, 'text.usetex': True, 'font.family': 'sans-serif', 'font.sans-serif': 'Helvetica'})
fig, ax = plt.subplots()
width = 10

bottom = np.zeros(len(timestamps))
ax.bar(timestamps, gv_coldstarts, width=width, label="Optimized", bottom=bottom)
bottom += gv_coldstarts
ax.bar(timestamps, hs_coldstarts, width=width, label="Unoptimized", bottom=bottom)

ax.set_xlabel("Time (s)")
ax.set_ylabel("Number of cold starts")

xticks = np.arange(0, 1801, 600)
yticks = np.arange(0, 41, 10)
ax.set_xticks(xticks)
ax.set_yticks(yticks)
ax.grid()

# ax.set_yscale('log')
ax.set_ylim(ymin=0, ymax=40)
ax.set_xlim(xmin=0, xmax=1800)
fig.set_figwidth(10)
fig.set_figheight(5)

ax.legend(ncol=5, loc='upper center')
plt.savefig("coldstarts.pdf", bbox_inches='tight')
plt.savefig("coldstarts.png", bbox_inches='tight')
plt.show()
