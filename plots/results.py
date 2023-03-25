#!/usr/bin/python

import numpy as np

def read_benchmark_throughput(path):
    tput = []
    try:
        with open('../results/' + path + '/ab.log') as file:
            for line in file:
                if 'Requests per second:' in line:
                    tput.append(float(line.split()[3]))
            tput = np.array(tput)
    except Exception as e:
        print("Error processing " + path + ":")
        raise e
    return tput

def read_benchmark_memory(path):
    mem = []
    try:
        mem = []
        with open('../results/' + path + '/lambda.rss') as file:
            for line in file:
                mem.append(int(line))
        if len(mem) < 7:
            print("Warning, not enough memory data points from {path}".format(path=path))
        mem = np.array(mem[-6:-1])
        # Convertion from KBs to MBs and to GBs.
        mem = mem / 1024 / 1024
    except Exception as e:
        print("Error processing " + path + ":")
        raise e
    return mem

def process_result(path):
    # Numpy array with throughput (ops/s) samples.
    tput = read_benchmark_throughput(path)
    # Last five memory samples (rss in GBs).
    mem = read_benchmark_memory(path)
    # Numpy array with the efficiency (ops/s/GB) samples.
    eff = tput / mem.mean()
    results = {}
    results["tput_avg"] = round(tput.mean(), 2)
    results["tput_std"] = round(tput.std(), 2)
    results["mem_avg"] = round(mem.mean(), 2)
    results["mem_std"] = round(mem.std(), 2)
    results["eff_avg"] = round(eff.mean(), 2)
    results["eff_std"] = round(eff.std(), 2)
    print("{path} {results}".format(path=path, results=results))
    return results
