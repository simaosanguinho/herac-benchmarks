#!/usr/bin/python

import declarations
import results
import matplotlib.pyplot as plt
import numpy as np

benchmark_labels = declarations.benchmark_labels
isolate_benchmark_path = declarations.isolate_benchmark_path 
process_benchmark_path = declarations.process_benchmark_path 
openwhisk_benchmark_path = declarations.openwhisk_benchmark_path 

# Efficiency in ops/s/gb.
isolate_eff_avg = {}
isolate_eff_std = {}
process_eff_avg = {}
process_eff_std = {}
openwhisk_eff_avg = {}
openwhisk_eff_std = {}

# Processing results.
for idx, path in enumerate(isolate_benchmark_path):
    isolate_eff_avg[idx] = results.process_result(path)["eff_avg"]
    isolate_eff_std[idx] = results.process_result(path)["eff_std"]
for idx, path in enumerate(process_benchmark_path):
    process_eff_avg[idx] = results.process_result(path)["eff_avg"]
    process_eff_std[idx] = results.process_result(path)["eff_std"]
for idx, path in enumerate(openwhisk_benchmark_path):
    openwhisk_eff_avg[idx] = results.process_result(path)["eff_avg"]
    openwhisk_eff_std[idx] = results.process_result(path)["eff_std"]

# Normalization to isolate.
for idx, path in enumerate(process_benchmark_path):
        process_eff_avg[idx] = process_eff_avg[idx] / isolate_eff_avg[idx]
        process_eff_std[idx] = process_eff_std[idx] / isolate_eff_avg[idx]
for idx, path in enumerate(openwhisk_benchmark_path):
        openwhisk_eff_avg[idx] = openwhisk_eff_avg[idx] / isolate_eff_avg[idx]
        openwhisk_eff_std[idx] = openwhisk_eff_std[idx] / isolate_eff_avg[idx]
for idx, path in enumerate(isolate_benchmark_path):
    isolate_eff_std[idx] = isolate_eff_std[idx] / isolate_eff_avg[idx]
    isolate_eff_avg[idx] = 1

x = np.arange(len(benchmark_labels))
width = 0.15

plt.rcParams.update({'font.size': 16})

fig, ax = plt.subplots()
ax.bar(x - width/3, isolate_eff_avg.values(), yerr=isolate_eff_std.values(), width=width, hatch='//', label='Graalvisor', alpha=0.75)
ax.bar(x +   width, openwhisk_eff_avg.values(), yerr=openwhisk_eff_std.values(), width=width, hatch='-',  label='OpenWhisk',  alpha=0.75)
ax.bar(x + width/3, process_eff_avg.values(), yerr=process_eff_std.values(), width=width, hatch='.',  label='SAND/SOCK', alpha=0.75)

ax.set_ylabel('Efficiency norm. to Isolate')
ax.set_xticks(x, benchmark_labels)
ax.set_axisbelow(True)
plt.grid(axis = 'y', linestyle = '--', linewidth = 0.25)
plt.xticks(rotation = 35)
fig.set_figwidth(10)
fig.set_figheight(4)

ax.legend(ncol=3, bbox_to_anchor=(.15, 1))
plt.savefig("sandboxes-efficiency-norm.pdf", bbox_inches='tight')
plt.savefig("sandboxes-efficiency-norm.png", bbox_inches='tight')
ax.legend(ncol=3)
plt.show()
