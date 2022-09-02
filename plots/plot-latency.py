#!/usr/bin/python

import os
import matplotlib.pyplot as plt
import numpy as np

results_home = "/home/rbruno/git/graalvm-argo-benchmarks/results"

benchmark_labels = [
    "jv/hello-world",
    "py/hello-world",
    "js/hello-world",
#    "java/sleep",
#    "python/sleep",
#    "javascript/sleep",
    "jv/file-hashing",
    "js/dynamic-html",
    "py/dynamic-html",
    "py/thumbnail",
    "js/uploader",
    "jv/httprequest",
    "jv/video-proc",
    "py/uploader",
    "py/compression",
    "py/video-proc",
    "jv/thumbnail" ]

gv_benchmark_path = [
    "java/gv-hello-world-niuk",
    "python/gv-hello-world-niuk",
    "javascript/gv-hello-world-niuk",
#    "java/gv-sleep-niuk",
#    "python/gv-sleep-niuk",
#    "javascript/gv-sleep-niuk",
    "java/gv-file-hashing-niuk",
    "javascript/gv-dynamic-html-niuk",
    "python/gv-dynamic-html-niuk",
    "python/gv-thumbnail-niuk",
    "javascript/gv-uploader-niuk",
    "java/gv-httprequest-niuk",
    "java/gv-video-processing-niuk",
    "python/gv-uploader-niuk",
    "python/gv-compression-niuk",
    "python/gv-video-processing-niuk",
    "javascript/gv-thumbnail-niuk" ]

cr_benchmark_path = [
    "java/cr-hello-world",
    "python/cr-hello-world",
    "javascript/cr-hello-world",
#    "java/cr-sleep",
#    "python/cr-sleep", 
#    "javascript/cr-sleep",
    "java/cr-file-hashing",
    "javascript/cr-dynamic-html",
    "python/cr-dynamic-html",
    "python/cr-thumbnail",
    "javascript/cr-uploader",
    "java/cr-httprequest",
    "java/cr-video-processing",
    "python/cr-uploader",
    "python/cr-compression",
    "python/cr-video-processing",
    "javascript/cr-thumbnail" ]

gv_benchmark_avg_latency = {}
cr_benchmark_avg_latency = {}

def read_benchmark_latency(path, values):
    try:
        benchmark_latency = []
        with open('../results/' + path + '/app.log') as file:
            for line in file:
                if 'Time taken:' in line:
                    benchmark_latency.append(int(line.split()[2]))
        last_five_elements = benchmark_latency[-5:]
        values[path] = int(sum(last_five_elements) / len(last_five_elements))
    except Exception as e:
        print("Error processing " + path + ":")
        raise e

for path in gv_benchmark_path: read_benchmark_latency(path, gv_benchmark_avg_latency)
for path in cr_benchmark_path: read_benchmark_latency(path, cr_benchmark_avg_latency)

x = np.arange(len(benchmark_labels))
width = 0.25

fig, ax = plt.subplots()
ax.bar(x - width/2, gv_benchmark_avg_latency.values(), width, label='Graalvisor')
ax.bar(x + width/2, cr_benchmark_avg_latency.values(), width, label='OpenWisk')

ax.set_ylabel('Time (us)')
ax.set_yscale('log')
ax.set_xticks(x, benchmark_labels)
ax.legend()
plt.xticks(rotation = 45)
plt.savefig("plot-latency.pdf")
plt.show()
