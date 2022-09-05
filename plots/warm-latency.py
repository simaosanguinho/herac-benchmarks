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
    "java/gv-hello-world-niuk-test-10-1-2048",
    "python/gv-hello-world-niuk-test-10-1-2048",
    "javascript/gv-hello-world-niuk-test-10-1-2048",
#    "java/gv-sleep-niuk-test-10-1-2048",
#    "python/gv-sleep-niuk-test-10-1-2048",
#    "javascript/gv-sleep-niuk-test-10-1-2048",
    "java/gv-file-hashing-niuk-test-10-1-2048",
    "javascript/gv-dynamic-html-niuk-test-10-1-2048",
    "python/gv-dynamic-html-niuk-test-10-1-2048",
    "python/gv-thumbnail-niuk-test-10-1-2048",
    "javascript/gv-uploader-niuk-test-10-1-2048",
    "java/gv-httprequest-niuk-test-10-1-2048",
    "java/gv-video-processing-niuk-test-10-1-2048",
    "python/gv-uploader-niuk-test-10-1-2048",
    "python/gv-compression-niuk-test-10-1-2048",
    "python/gv-video-processing-niuk-test-10-1-2048",
    "javascript/gv-thumbnail-niuk-test-10-1-2048" ]

cr_benchmark_path = [
    "java/cr-hello-world-test-10-1-2048",
    "python/cr-hello-world-test-10-1-2048",
    "javascript/cr-hello-world-test-10-1-2048",
#    "java/cr-sleep-test-10-1-2048",
#    "python/cr-sleep-test-10-1-2048", 
#    "javascript/cr-sleep-test-10-1-2048",
    "java/cr-file-hashing-test-10-1-2048",
    "javascript/cr-dynamic-html-test-10-1-2048",
    "python/cr-dynamic-html-test-10-1-2048",
    "python/cr-thumbnail-test-10-1-2048",
    "javascript/cr-uploader-test-10-1-2048",
    "java/cr-httprequest-test-10-1-2048",
    "java/cr-video-processing-test-10-1-2048",
    "python/cr-uploader-test-10-1-2048",
    "python/cr-compression-test-10-1-2048",
    "python/cr-video-processing-test-10-1-2048",
    "javascript/cr-thumbnail-test-10-1-2048" ]

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
plt.savefig("warm-latency.pdf")
plt.show()
