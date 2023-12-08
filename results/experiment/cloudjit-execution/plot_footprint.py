import matplotlib
import matplotlib.pyplot as plt
import numpy as np


def normalize(data):
    i = 1
    while i < len(data):
        if data[i] == 0:
            j = i
            while j < len(data) and data[j] == 0:
                j += 1
            if j < len(data):
                data[i] = np.mean([data[i-1], data[j]])
        i += 1


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

hs = hs[:2000]
pl = pl[:2000]

# normalize(hs)
# normalize(pl)

# window_width = 100
# cumsum_vec = np.cumsum(np.insert(hs, 0, 0)) 
# hs = (cumsum_vec[window_width:] - cumsum_vec[:-window_width]) / window_width
# cumsum_vec = np.cumsum(np.insert(pl, 0, 0)) 
# pl = (cumsum_vec[window_width:] - cumsum_vec[:-window_width]) / window_width

kernel_size = 50
kernel = np.ones(kernel_size) / kernel_size
hs = np.convolve(hs, kernel, mode='same')
pl = np.convolve(pl, kernel, mode='same')

# Stretch data to fit 1800 seconds
hs = np.array(stretch(hs))
pl = np.array(stretch(pl))

# Convert MB to GB
hs = hs / 1024
pl = pl / 1024

x = np.arange(0, max(len(hs), len(pl)))

len_diff = len(pl) - len(hs)
hs = np.append(hs, np.zeros(len_diff))

plt.rcParams.update({'font.size': 22, 'text.usetex': True, 'font.family': 'sans-serif', 'font.sans-serif': 'Helvetica'})
fig, ax = plt.subplots()

ax.plot(x, pl, linewidth=3, linestyle="--", label='With CloudJIT')
ax.plot(x, hs, linewidth=3, label='Without CloudJIT')

ax.set_xlabel("Time (s)")
ax.set_ylabel("Memory (GB)")

xticks = np.arange(0, 1801, 600)
ax.set_xticks(xticks)
ax.grid()

# plt.yscale('log', base=10)
ax.set_ylim(ymin=0, ymax=70)
ax.set_xlim(xmin=0, xmax=1800)
fig.set_figwidth(10)
fig.set_figheight(5)

ax.legend(ncol=5, loc='upper center')
plt.savefig("footprint.pdf", bbox_inches='tight')
plt.savefig("footprint.png", bbox_inches='tight')
plt.show()
