#!/usr/bin/python

import declarations
import results
import matplotlib.pyplot as plt
import numpy as np

benchmark_labels = declarations.benchmark_labels
isolate_benchmark_path = declarations.isolate_benchmark_path 
process_benchmark_path = declarations.process_benchmark_path 
openwhisk_benchmark_path = declarations.openwhisk_benchmark_path 

# Throughput in ops/s.
isolate_tput_avg = {}
isolate_tput_std = {}
process_tput_avg = {}
process_tput_std = {}
openwhisk_tput_avg = {}
openwhisk_tput_std = {}

# Processing results.
for idx, path in enumerate(isolate_benchmark_path):
    isolate_tput_avg[idx] = results.process_result(path)["tput_avg"]
    isolate_tput_std[idx] = results.process_result(path)["tput_std"]
for idx, path in enumerate(process_benchmark_path):
    process_tput_avg[idx] = results.process_result(path)["tput_avg"]
    process_tput_std[idx] = results.process_result(path)["tput_std"]
for idx, path in enumerate(openwhisk_benchmark_path):
    openwhisk_tput_avg[idx] = results.process_result(path)["tput_avg"]
    openwhisk_tput_std[idx] = results.process_result(path)["tput_std"]

# Scale openwhisk to 2GB.
for idx, path in enumerate(openwhisk_benchmark_path):
    openwhisk_tput_avg[idx] = openwhisk_tput_avg[idx] * (2048 / declarations.openwhisk_mem_factor[idx])

# Normalization to isolate.
for idx, path in enumerate(process_benchmark_path):
        process_tput_avg[idx] = process_tput_avg[idx] / isolate_tput_avg[idx]
        process_tput_std[idx] = process_tput_std[idx] / isolate_tput_avg[idx]
for idx, path in enumerate(openwhisk_benchmark_path):
        openwhisk_tput_avg[idx] = openwhisk_tput_avg[idx] / isolate_tput_avg[idx]
        openwhisk_tput_std[idx] = openwhisk_tput_std[idx] / isolate_tput_avg[idx]
for idx, path in enumerate(isolate_benchmark_path):
    isolate_tput_std[idx] = isolate_tput_std[idx] / isolate_tput_avg[idx]
    isolate_tput_avg[idx] = 1

x = np.arange(len(benchmark_labels))
width = 0.15

plt.rcParams.update({'font.size': 16})

fig, ax = plt.subplots()
ax.bar(x - width/3, isolate_tput_avg.values(), yerr=isolate_tput_std.values(), width=width, hatch='//', label='Graalvisor', alpha=0.75)
ax.bar(x - width/3, openwhisk_tput_avg.values(), yerr=openwhisk_tput_std.values(), width=width, hatch='-', label='OpenWhisk', alpha=0.75)
ax.bar(x + width/3, process_tput_avg.values(), yerr=process_tput_std.values(), width=width, hatch='.',  label='SAND/SOCK', alpha=0.75)

ax.set_ylabel('Tput norm. to Isolate')
ax.set_xticks(x, benchmark_labels)
ax.legend(ncol=3)
ax.set_axisbelow(True)
plt.grid(axis = 'y', linestyle = '--', linewidth = 0.25)
plt.xticks(rotation = 35)
fig.set_figwidth(10)
fig.set_figheight(4)

ax.legend(ncol=3, bbox_to_anchor=(.15, 1))
plt.savefig("sandboxes-tput-norm.pdf", bbox_inches='tight')
plt.savefig("sandboxes-tput-norm.png", bbox_inches='tight')
ax.legend(ncol=3)
plt.show()
plt.show()
