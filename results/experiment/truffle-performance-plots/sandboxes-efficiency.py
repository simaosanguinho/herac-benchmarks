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

# Efficiency in ops/s/gb.
nojit_eff_avg = {}
nojit_eff_std = {}
jit_eff_avg = {}
jit_eff_std = {}
openwhisk_eff_avg = {}
openwhisk_eff_std = {}
snapshot_eff_avg = {}
snapshot_eff_std = {}

# Processing results.
for idx, path in enumerate(isolate_benchmark_path):
    nojit_eff_avg[idx] = results.process_result(nojit_exp + path)["eff_avg"]
    nojit_eff_std[idx] = results.process_result(nojit_exp + path)["eff_std"]
for idx, path in enumerate(isolate_benchmark_path):
    jit_eff_avg[idx] = results.process_result(jit_exp + path)["eff_avg"]
    jit_eff_std[idx] = results.process_result(jit_exp + path)["eff_std"]
for idx, path in enumerate(openwhisk_benchmark_path):
    openwhisk_eff_avg[idx] = results.process_result(nojit_exp + path)["eff_avg"]
    openwhisk_eff_std[idx] = results.process_result(nojit_exp + path)["eff_std"]
for idx, path in enumerate(snapshot_benchmark_path):
    snapshot_eff_avg[idx] = results.process_result(nojit_exp + path)["eff_avg"]
    snapshot_eff_std[idx] = results.process_result(nojit_exp + path)["eff_std"]

x = np.arange(len(benchmark_labels))
width = 0.15

plt.rcParams.update({'font.size': 12})
fig, ax = plt.subplots()
ax.bar(x + 0*width, nojit_eff_avg.values(),     yerr=nojit_eff_std.values(),     width=width, hatch='*', label='Hydra',  alpha=0.75)
ax.bar(x + 1*width, jit_eff_avg.values(),       yerr=jit_eff_std.values(),       width=width, hatch='*', label='Hydra (nojit)',  alpha=0.75)
ax.bar(x + 2*width, snapshot_eff_avg.values(),  yerr=snapshot_eff_std.values(),  width=width, hatch='/', label='VM Snapshot', alpha=0.75)
ax.bar(x + 3*width, openwhisk_eff_avg.values(), yerr=openwhisk_eff_std.values(), width=width, hatch='-', label='OpenWhisk',   alpha=0.75)

ax.set_ylabel('Efficiency (ops/GB-sec)')
ax.set_xticks(x, benchmark_labels)
ax.set_axisbelow(True)
plt.grid(axis = 'y', linestyle = '--', linewidth = 0.25)
plt.xticks(rotation = 35)
ax.set_yscale('log')
fig.set_figwidth(15)
fig.set_figheight(3)

ax.legend(ncol=5, loc='upper center')
plt.savefig("sandboxes-efficiency.pdf", bbox_inches='tight')
plt.savefig("sandboxes-efficiency.png", bbox_inches='tight')