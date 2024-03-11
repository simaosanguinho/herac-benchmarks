#!/usr/bin/env python

import matplotlib.pyplot as plt
import numpy as np

benchmark_labels = [
    "jv/hw",
    "jv/hash",
    "jv/rest",
    "js/html",
    "js/upload",
    "js/hw",
    "py/hw",
    "py/html",
    "py/upload",
    "py/compress",
    "py/mst",
    "py/bfs",
    "py/pr",
    "py/dna",
]


normal_entrypoint = [
    .017,
    3510,
    4274,
    20983,
    8088,
    5372,
    145251,
    1634348,
    1679889,
    601977,
    169338,
    184028,
    1515144,
    1678104
]

normal_memory = [
    8152,
    16452,
    15584,
    83756,
    63456,
    52900,
    171168,
    312380,
    310976,
    193064,
    171736,
    172108,
    327548,
    310972
]

restore = [
    139,
    166,
    188,
    483,
    675,
    144,
    859,
    6361,
    3641,
    1389,
    1950,
    987,
    4318,
    3447
]

restored_entrypoint = [
    53,
    1808,
    2211,
    2786,
    3464,
    1250,
    1216,
    133407,
    259844,
    20475,
    2615,
    2747,
    29174,
    3275
]

restored_total = [x + y for x, y in zip(restore, restored_entrypoint)]
restored_memory = [
    4916,
    13364,
    11904,
    31528,
    24340,
    13756,
    23164,
    190116,
    214064,
    81764,
    37528,
    41980,
    118908,
    47308
]

print(normal_entrypoint)
print(restored_total)
# Normalized entrypoint.
li = [x / y for x, y in zip(normal_entrypoint, restored_total)]
mi = [x / y for x, y in zip(normal_memory, restored_memory)]
print("Normalized latency improvement:")
print(li)
print("Normalized memory improvement:")
print(mi)
print("Average latency improvement:" + str(sum(li) / len(li)) )
print("Average memry improvement:" + str(sum(mi) / len(mi)) )


x = np.arange(len(benchmark_labels))
plt.rcParams.update({'font.size': 12})
fig, axs = plt.subplots(2)
width = 0.3

axs[0].bar(x + 0*width, normal_entrypoint,   width=width, hatch='...', label='Cold',  alpha=0.75)
axs[0].bar(x + 1*width, restored_total,      width=width, hatch='|||', label='Snap',  alpha=0.75)

axs[1].bar(x + 0*width, normal_memory,   width=width, hatch='...', label='Cold',  alpha=0.75)
axs[1].bar(x + 1*width, restored_memory, width=width, hatch='|||', label='Snap',  alpha=0.75)
axs[0].set_xticks([])
axs[1].set_xticks(x, benchmark_labels)
axs[1].legend()
plt.xticks(rotation = 45)
axs[0].grid(axis = 'y', linestyle = '--', linewidth = 0.25)
axs[1].grid(axis = 'y', linestyle = '--', linewidth = 0.25)
axs[0].set_ylabel('Latency (ms)')
axs[1].set_ylabel('Memory (MBs)')
axs[0].set_yscale('log')
axs[1].set_yscale('log')
fig.set_figwidth(7)
fig.set_figheight(3)

plt.savefig("sandboxes-snapshot.pdf", bbox_inches='tight')
plt.savefig("sandboxes-snapshot.png", bbox_inches='tight')