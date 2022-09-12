#!/usr/bin/python

import os
import matplotlib.pyplot as plt
import numpy as np

results_home = "/home/rbruno/git/graalvm-argo-benchmarks/results"

benchmark_labels = [
    "jv/hw",
    "py/hw",
    "js/hw",
#    "java/sleep",
#    "python/sleep",
#    "javascript/sleep",
    "jv/fhashing",
    "js/dy-html",
    "py/dy-html",
    "py/thumbnail",
    "js/uploader",
    "jv/rest",
    "jv/video",
    "py/uploader",
    "py/compress",
    "py/video",
    "jv/thumbnail" 
]

gv_benchmark_path = [
    "java/gv-hello-world-niuk-benchmark-8-1-2048",
    "python/gv-hello-world-niuk-benchmark-8-1-2048",
    "javascript/gv-hello-world-niuk-benchmark-8-1-2048",
#    "java/gv-sleep-niuk-benchmark-10-1-2048",
#    "python/gv-sleep-niuk-benchmark-10-1-2048",
#    "javascript/gv-sleep-niuk-benchmark-10-1-2048",
    "java/gv-file-hashing-niuk-benchmark-8-1-2048",
    "javascript/gv-dynamic-html-niuk-benchmark-8-1-2048",
    "python/gv-dynamic-html-niuk-benchmark-8-1-2048",
    "python/gv-thumbnail-niuk-benchmark-8-1-2048",
    "javascript/gv-uploader-niuk-benchmark-8-1-2048",
    "java/gv-httprequest-niuk-benchmark-8-1-2048",
    "java/gv-video-processing-niuk-benchmark-2-1-2048",
    "python/gv-uploader-niuk-benchmark-8-1-2048",
    "python/gv-compression-niuk-benchmark-4-1-2048",
    "python/gv-video-processing-niuk-benchmark-4-1-2048",
    "javascript/gv-thumbnail-niuk-benchmark-4-1-2048" 
]

cr_benchmark_path = [
    "java/cr-hello-world-benchmark-1-1-256",
    "python/cr-hello-world-benchmark-1-1-256",
    "javascript/cr-hello-world-benchmark-1-1-256",
#    "java/cr-sleep-benchmark-10-1-2048",
#    "python/cr-sleep-benchmark-10-1-2048", 
#    "javascript/cr-sleep-benchmark-10-1-2048",
    "java/cr-file-hashing-benchmark-1-1-256",
    "javascript/cr-dynamic-html-benchmark-1-1-256",
    "python/cr-dynamic-html-benchmark-1-1-256",
    "python/cr-thumbnail-benchmark-1-1-256",
    "javascript/cr-uploader-benchmark-1-1-256",
    "java/cr-httprequest-benchmark-1-1-256",
    "java/cr-video-processing-benchmark-1-1-1024",
    "python/cr-uploader-benchmark-1-1-256",
    "python/cr-compression-benchmark-1-1-256",
    "python/cr-video-processing-benchmark-1-1-512",
    "javascript/cr-thumbnail-benchmark-1-1-512"
]

# Throughput in ops/s.
gv_benchmark_tput = {}
cr_benchmark_tput = {}
# RSS in MBs.
gv_benchmark_rss = {}
cr_benchmark_rss = {}
# Efficiency in ops/s/mb.
gv_benchmark_eff = {}
cr_benchmark_eff = {}

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

for path in gv_benchmark_path: read_benchmark_throughput(path, gv_benchmark_tput)
for path in cr_benchmark_path: read_benchmark_throughput(path, cr_benchmark_tput)
for path in gv_benchmark_path: read_benchmark_rss(path, gv_benchmark_rss)
for path in cr_benchmark_path: read_benchmark_rss(path, cr_benchmark_rss)

for path in cr_benchmark_tput:
    cr_benchmark_eff[path] = cr_benchmark_tput[path] / cr_benchmark_rss[path] * 1024
for path in gv_benchmark_tput:
    gv_benchmark_eff[path] = gv_benchmark_tput[path] / gv_benchmark_rss[path] * 1024

print(gv_benchmark_tput)
print(cr_benchmark_tput)
print(gv_benchmark_rss)
print(cr_benchmark_rss)
print(gv_benchmark_eff)
print(cr_benchmark_eff)

x = np.arange(len(benchmark_labels))
width = 0.25

fig, ax = plt.subplots()
ax.bar(x - width/2, gv_benchmark_eff.values(), width, label='Graalvisor')
ax.bar(x + width/2, cr_benchmark_eff.values(), width, label='OpenWisk')

ax.set_ylabel('Tput/Mem (Ops/Second/GB)')
ax.set_yscale('log')
ax.set_ylim(ymin=0.1)
ax.set_xticks(x, benchmark_labels)
ax.legend()
plt.xticks(rotation = 45)
fig.set_figwidth(10)
fig.set_figheight(3)
plt.savefig("memory.pdf", bbox_inches='tight')
plt.show()
