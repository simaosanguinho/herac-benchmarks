#!/usr/bin/env python

import results
import matplotlib.pyplot as plt

# TODO - remove java from the experiment name.
# TODO - remove isolate when we are using snapshot.
# TODO - implement a timeout for an experiment.

benchmarks = [
    "hello-world",
    "file-hashing",
    "httprequest",
    "video-processing",
    "classify",
    "js-dynamic-html",
    "js-uploader",
    "js-thumbnail",
    "js-hello-world",
    "py-hello-world",
    "py-dynamic-html",
    "py-thumbnail",
    "py-uploader",
    "py-compression",
    "py-video-processing",
    "py-mst",
    "py-bfs",
    "py-pagerank",
    "py-dna",
    "py-classify",
]

# Memory budget per concurrency level.
conc_memory = {}
conc_memory[1] = 2048
conc_memory[2] = 1024
conc_memory[4] = 512
conc_memory[8] = 256

# Concurrency values we tested with (see scripts/run-experiment.sh).
concurrencies = [1, 2, 4, 8]

# Set global font size.
plt.rcParams.update({'font.size': 12})

def handle_benchmark(benchmark):
    fig, ax = plt.subplots()
    isolate = []
    process = []
    vm = []
    snapshot = []
    openwhisk = []
    lang = "python" if benchmark.startswith("py") else "javascript" if benchmark.startswith("js") else "java"

    for concurrency in concurrencies:
        sandbox = "isolate" if lang == "java" else "context"
        # TODO - isolation is context if py or js. Otherwise isolate
        # Isolate/Context
        path = "gv-{benchmark}-vm-{sandbox}-benchmark-{concurrency}-1-2048".format(benchmark=benchmark, sandbox=sandbox, concurrency=concurrency)
        res = results.process_result("java/" + path)["tput_avg"]
        isolate.append(res)

        # Process
        path = "gv-{benchmark}-vm-process-benchmark-{concurrency}-1-2048".format(benchmark=benchmark, concurrency=concurrency)
        res = results.process_result("java/" + path)["tput_avg"]
        process.append(res)

        # Isolate/Context single
        path = "gv-{benchmark}-vm-{sandbox}-benchmark-1-1-{memory}".format(benchmark=benchmark, sandbox=sandbox, memory=conc_memory[concurrency])
        res = results.process_result("java/" + path)["tput_avg"]
        vm.append(res * concurrency)

        # VM snapshot
        path = "gv-{benchmark}-vm-snapshot-{sandbox}-benchmark-1-1-{memory}".format(benchmark=benchmark, sandbox=sandbox, memory=conc_memory[concurrency])
        res = results.process_result("java/" + path)["tput_avg"]
        snapshot.append(res * concurrency)

        # Openwhisk
        crbenchmark = benchmark.replace("py-", "").replace("js-", "")
        path = "cr-{crbenchmark}-vm-benchmark-1-1-{memory}".format(crbenchmark=crbenchmark, memory=conc_memory[concurrency])
        res = results.process_result(lang + "/" + path)["tput_avg"]
        openwhisk.append(res * concurrency)

    ax.plot(concurrencies, isolate,     label='isolate')
    ax.plot(concurrencies, process,     label='process')
    ax.plot(concurrencies, vm,          label='vm')
    ax.plot(concurrencies, snapshot,    label='snapshot')
    ax.plot(concurrencies, openwhisk,   label='openwhisk')
    ax.set_xlabel('Concurrency')
    ax.set_ylabel('Throughput (ops/2*GB-sec)')
    ax.legend(ncol=2, loc='upper right')
    plt.title(benchmark)
    plt.savefig("sandboxes-resources-{lang}-{benchmark}.pdf".format(lang=lang, benchmark=benchmark), bbox_inches='tight')
    plt.savefig("sandboxes-resources-{lang}-{benchmark}.png".format(lang=lang, benchmark=benchmark), bbox_inches='tight')

for benchmark in benchmarks:
    try:
        handle_benchmark(benchmark)
    except FileNotFoundError as error:
        print("Warning, ignoring {} due to missing output: {}".format(benchmark, error.filename))