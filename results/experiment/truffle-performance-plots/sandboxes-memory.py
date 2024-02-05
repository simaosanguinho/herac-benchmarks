#!/usr/bin/env python

declarations = __import__("sandboxes-declarations")
import results
import matplotlib.pyplot as plt
import numpy as np

nojit_exp = declarations.nojit_experiment
jit_exp = declarations.jit_experiment
benchmark_labels = declarations.benchmark_labels
isolate_benchmark_path = declarations.isolate_benchmark_path
openwhisk_benchmark_path = declarations.openwhisk_benchmark_path
snapshot_benchmark_path = declarations.snapshot_benchmark_path

# Memory footprint in GBs.
nojit_mem_avg = {}
nojit_mem_std = {}
jit_mem_avg = {}
jit_mem_std = {}
openwhisk_mem_avg = {}
openwhisk_mem_std = {}
snapshot_mem_avg = {}
snapshot_mem_std = {}

# Processing results.
for idx, path in enumerate(isolate_benchmark_path):
    nojit_mem_avg[idx] = results.process_result(nojit_exp + path)["mem_avg"]
    nojit_mem_std[idx] = results.process_result(nojit_exp + path)["mem_std"]
for idx, path in enumerate(isolate_benchmark_path):
    jit_mem_avg[idx] = results.process_result(jit_exp + path)["mem_avg"]
    jit_mem_std[idx] = results.process_result(jit_exp + path)["mem_std"]
for idx, path in enumerate(openwhisk_benchmark_path):
    openwhisk_mem_avg[idx] = results.process_result(nojit_exp + path)["mem_avg"]
    openwhisk_mem_std[idx] = results.process_result(nojit_exp + path)["mem_std"]
for idx, path in enumerate(snapshot_benchmark_path):
    snapshot_mem_avg[idx] = results.process_result(nojit_exp + path)["mem_avg"]
    snapshot_mem_std[idx] = results.process_result(nojit_exp + path)["mem_std"]

# Scale openwhisk and snapshot to 2GB.
for idx, path in enumerate(openwhisk_benchmark_path):
    openwhisk_mem_avg[idx] = openwhisk_mem_avg[idx] * (2048 / declarations.openwhisk_mem_factor[idx])
for idx, path in enumerate(snapshot_benchmark_path):
    snapshot_mem_avg[idx] = snapshot_mem_avg[idx] * (2048 / declarations.snapshot_mem_factor[idx])

x = np.arange(len(benchmark_labels))
width = 0.15

plt.rcParams.update({'font.size': 12})
fig, ax = plt.subplots()
ax.bar(x + 0*width, nojit_mem_avg.values(),     yerr=nojit_mem_std.values(),     width=width, hatch='*', label='Hydra', alpha=0.75)
ax.bar(x + 1*width, jit_mem_avg.values(),       yerr=jit_mem_std.values(),       width=width, hatch='*', label='Hydra (nojit)', alpha=0.75)
ax.bar(x + 2*width, snapshot_mem_avg.values(),  yerr=snapshot_mem_std.values(),  width=width, hatch='/', label='VM Snapshot', alpha=0.75)
ax.bar(x + 3*width, openwhisk_mem_avg.values(), yerr=openwhisk_mem_std.values(), width=width, hatch='-', label='OpenWhisk',  alpha=0.75)

ax.set_ylabel('Memory (GBs)')
ax.set_xticks(x, benchmark_labels)

# Uncomment to hide xticks.
#plt.tick_params(
#    axis='x',          # changes apply to the x-axis
#    which='both',      # both major and minor ticks are affected
#    bottom=False,      # ticks along the bottom edge are off
#    top=False,         # ticks along the top edge are off
#    labelbottom=False) # labels along the bottom edge are off
ax.set_axisbelow(True)
plt.grid(axis = 'y', linestyle = '--', linewidth = 0.25)
plt.xticks(rotation = 35)
ax.set_ylim(ymax=2.1)
#ax.set_xlim(xmin=-.25, xmax=14.7)
fig.set_figwidth(15)
fig.set_figheight(3)

ax.legend(ncol=5, loc='upper center')
plt.savefig("sandboxes-memory.pdf", bbox_inches='tight')
plt.savefig("sandboxes-memory.png", bbox_inches='tight')
