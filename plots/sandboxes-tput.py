#!/usr/bin/env python

declarations = __import__("sandboxes-declarations")
import results
import matplotlib.pyplot as plt
import numpy as np

experiment = declarations.experiment
benchmark_labels = declarations.benchmark_labels
isolate_benchmark_path = declarations.isolate_benchmark_path
process_benchmark_path = declarations.process_benchmark_path
openwhisk_benchmark_path = declarations.openwhisk_benchmark_path
nift_benchmark_path = declarations.nitf_benchmark_path
snapshot_benchmark_path = declarations.snapshot_benchmark_path

# Throughput in ops/s.
isolate_tput_avg = {}
isolate_tput_std = {}
process_tput_avg = {}
process_tput_std = {}
openwhisk_tput_avg = {}
openwhisk_tput_std = {}
nift_tput_avg = {}
nift_tput_std = {}
snapshot_tput_avg = {}
snapshot_tput_std = {}

# Processing results.
for idx, path in enumerate(isolate_benchmark_path):
    isolate_tput_avg[idx] = results.process_result(experiment + path)["tput_avg"]
    isolate_tput_std[idx] = results.process_result(experiment + path)["tput_std"]
for idx, path in enumerate(process_benchmark_path):
    process_tput_avg[idx] = results.process_result(experiment + path)["tput_avg"]
    process_tput_std[idx] = results.process_result(experiment + path)["tput_std"]
for idx, path in enumerate(openwhisk_benchmark_path):
    openwhisk_tput_avg[idx] = results.process_result(experiment + path)["tput_avg"]
    openwhisk_tput_std[idx] = results.process_result(experiment + path)["tput_std"]
for idx, path in enumerate(nift_benchmark_path):
    nift_tput_avg[idx] = results.process_result(experiment + path)["tput_avg"]
    nift_tput_std[idx] = results.process_result(experiment + path)["tput_std"]
for idx, path in enumerate(snapshot_benchmark_path):
    snapshot_tput_avg[idx] = results.process_result(experiment + path)["tput_avg"]
    snapshot_tput_std[idx] = results.process_result(experiment + path)["tput_std"]

# Scale openwhisk to 2GB.
for idx, path in enumerate(openwhisk_benchmark_path):
    openwhisk_tput_avg[idx] = openwhisk_tput_avg[idx] * (2048 / declarations.openwhisk_mem_factor[idx])
for idx, path in enumerate(snapshot_benchmark_path):
    snapshot_tput_avg[idx] = snapshot_tput_avg[idx] * (2048 / declarations.snapshot_mem_factor[idx])
for idx, path in enumerate(nift_benchmark_path):
    nift_tput_avg[idx] = nift_tput_avg[idx] * (2048 / declarations.nift_mem_factor[idx])

x = np.arange(len(benchmark_labels))
width = 0.15

plt.rcParams.update({'font.size': 12})
fig, ax = plt.subplots()
ax.bar(x + 0*width, isolate_tput_avg.values(),   yerr=isolate_tput_std.values(),   width=width, hatch='*', label='Hydra', alpha=0.75)
ax.bar(x + 1*width, process_tput_avg.values(),   yerr=process_tput_std.values(),   width=width, hatch='.', label='Forking',  alpha=0.75)
ax.bar(x + 2*width, nift_tput_avg.values(),      yerr=nift_tput_std.values(),      width=width, hatch='O', label='NI+TF',    alpha=0.75)
ax.bar(x + 3*width, snapshot_tput_avg.values(),  yerr=snapshot_tput_std.values(),  width=width, hatch='/', label='VM Snapshot', alpha=0.75)
ax.bar(x + 4*width, openwhisk_tput_avg.values(), yerr=openwhisk_tput_std.values(), width=width, hatch='-', label='OpenWhisk',  alpha=0.75)

ax.set_ylabel('Throughput (ops/s)')
ax.set_xticks(x, benchmark_labels)
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
ax.set_ylim(ymin=0.1, ymax=100000)
#ax.set_xlim(xmin=-.25, xmax=14.7)
fig.set_figwidth(15)
fig.set_figheight(3)

ax.legend(ncol=5, loc='upper center')
plt.savefig("sandboxes-tput.pdf", bbox_inches='tight')
plt.savefig("sandboxes-tput.png", bbox_inches='tight')
