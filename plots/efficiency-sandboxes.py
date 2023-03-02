#!/usr/bin/python

import os
import matplotlib.pyplot as plt
import numpy as np

results_home = "/home/rbruno/git/graalvm-argo-benchmarks/results"

benchmark_labels = [
    "jv/hw",
#    "java/sleep",
    "jv/hashing",
    "jv/rest",
    "jv/video",
    "jv/classify"
]

isolate_benchmark_path = [
    "java/gv-hello-world-niuk-isolate-benchmark-8-1-2048",
#    "java/gv-sleep-niuk-benchmark-10-1-2048",
    "java/gv-file-hashing-niuk-isolate-benchmark-8-1-2048",
    "java/gv-httprequest-niuk-isolate-benchmark-8-1-2048",
    "java/gv-video-processing-niuk-isolate-benchmark-2-1-2048",
    "java/gv-classify-niuk-isolate-benchmark-1-1-2048",
]

runtime_benchmark_path = [
    "java/gv-hello-world-niuk-runtime-benchmark-8-1-2048",
#    "java/gv-sleep-niuk-benchmark-10-1-2048",
    "java/gv-file-hashing-niuk-runtime-benchmark-8-1-2048",
    "java/gv-httprequest-niuk-runtime-benchmark-8-1-2048",
    "java/gv-video-processing-niuk-runtime-benchmark-2-1-2048",
    "java/gv-classify-niuk-runtime-benchmark-1-1-2048",
]

process_benchmark_path = [
    "java/gv-hello-world-niuk-process-benchmark-8-1-2048",
#    "java/gv-sleep-niuk-benchmark-10-1-2048",
    "java/gv-file-hashing-niuk-process-benchmark-8-1-2048",
    "java/gv-httprequest-niuk-process-benchmark-8-1-2048",
    "java/gv-video-processing-niuk-process-benchmark-2-1-2048",
    "java/gv-classify-niuk-process-benchmark-1-1-2048",
]

# Throughput in ops/s.
isolate_benchmark_tput = {}
runtime_benchmark_tput = {}
process_benchmark_tput = {}
# RSS in MBs.
isolate_benchmark_rss = {}
runtime_benchmark_rss = {}
process_benchmark_rss = {}
# Efficiency in ops/s/mb.
isolate_benchmark_eff = {}
runtime_benchmark_eff = {}
process_benchmark_eff = {}

def read_benchmark_throughput(path, values):
    try:
        with open('../results/' + path + '/ab.log') as file:
            for line in file:
                if 'Requests per second:' in line:
                    values[path] = float(line.split()[3])
    except Exception as e:
        print("Error processing " + path + ":")
        raise e

def read_benchmark_rss(path, values):
    try:
        benchmark_rss = []
        with open('../results/' + path + '/lambda.rss') as file:
            for line in file:
                benchmark_rss.append(int(line))
        last_five_elements = benchmark_rss[-5:]
        values[path] = int(sum(last_five_elements) / len(last_five_elements) / 1000)
    except Exception as e:
        print("Error processing " + path + ":")
        raise e

for path in isolate_benchmark_path: read_benchmark_throughput(path, isolate_benchmark_tput)
for path in runtime_benchmark_path: read_benchmark_throughput(path, runtime_benchmark_tput)
for path in process_benchmark_path: read_benchmark_throughput(path, process_benchmark_tput)
for path in isolate_benchmark_path: read_benchmark_rss(path, isolate_benchmark_rss)
for path in runtime_benchmark_path: read_benchmark_rss(path, runtime_benchmark_rss)
for path in process_benchmark_path: read_benchmark_rss(path, process_benchmark_rss)

for path in isolate_benchmark_tput:
    isolate_benchmark_eff[path] = isolate_benchmark_tput[path] / isolate_benchmark_rss[path] * 1024
for path in runtime_benchmark_tput:
    runtime_benchmark_eff[path] = runtime_benchmark_tput[path] / runtime_benchmark_rss[path] * 1024
for path in process_benchmark_tput:
    process_benchmark_eff[path] = process_benchmark_tput[path] / process_benchmark_rss[path] * 1024


print("########## Throughput ##########")
for key in isolate_benchmark_tput:
    print("{benchmark}: {value} ops/s".format(benchmark=key, value=isolate_benchmark_tput[key]))
for key in runtime_benchmark_tput:
    print("{benchmark}: {value} ops/s".format(benchmark=key, value=runtime_benchmark_tput[key]))
for key in process_benchmark_tput:
    print("{benchmark}: {value} ops/s".format(benchmark=key, value=process_benchmark_tput[key]))


print("########## Memory ##############")
for key in isolate_benchmark_tput:
    print("{benchmark}: {value} KBs".format(benchmark=key, value=isolate_benchmark_rss[key]))
for key in runtime_benchmark_tput:
    print("{benchmark}: {value} KBs".format(benchmark=key, value=runtime_benchmark_rss[key]))
for key in process_benchmark_tput:
    print("{benchmark}: {value} KBs".format(benchmark=key, value=process_benchmark_rss[key]))


print("########## Efficiency ##########")
for key in isolate_benchmark_eff:
    print("{benchmark}: {value} ops/sec/GB".format(benchmark=key, value=isolate_benchmark_eff[key]))
for key in runtime_benchmark_eff:
    print("{benchmark}: {value} ops/sec/GB".format(benchmark=key, value=runtime_benchmark_eff[key]))
for key in process_benchmark_eff:
    print("{benchmark}: {value} ops/sec/GB".format(benchmark=key, value=process_benchmark_eff[key]))


print("########## Efficiency Imp. #####")
for i in range(len(benchmark_labels)):
    print("{benchmark}: {value} efficiency improvement w/ gv".format(benchmark=benchmark_labels[i], value=isolate_benchmark_eff[isolate_benchmark_path[i]]/runtime_benchmark_eff[runtime_benchmark_path[i]]))
    print("{benchmark}: {value} efficiency improvement w/ gv".format(benchmark=benchmark_labels[i], value=isolate_benchmark_eff[isolate_benchmark_path[i]]/process_benchmark_eff[process_benchmark_path[i]]))

x = np.arange(len(benchmark_labels))
width = 0.15

fig, ax = plt.subplots()
ax.bar(x - width, isolate_benchmark_eff.values(), width, hatch='//', label='Isolate', alpha=0.75)
ax.bar(x          , runtime_benchmark_eff.values(), width, hatch='..', label='Runtime', alpha=0.75)
ax.bar(x + width, process_benchmark_eff.values(), width, hatch='.', label='Process', alpha=0.75)

ax.set_ylabel('Tput/Mem (Ops/Second/GB)')
ax.set_yscale('log')
ax.set_ylim(ymin=0.1)
ax.set_xticks(x, benchmark_labels)
ax.legend()
ax.set_axisbelow(True)
plt.grid(axis = 'y', linestyle = '--', linewidth = 0.25)
plt.xticks(rotation = 35)
fig.set_figwidth(10)
fig.set_figheight(3)
plt.savefig("efficiency-java.pdf", bbox_inches='tight')
plt.show()
