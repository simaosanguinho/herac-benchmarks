#!/bin/python3

import sys
import os
import re
import shutil
import pathlib
import statistics
import numpy as np
from matplotlib import pyplot as plt

timestamp_regex = re.compile(r'^\[(?P<ts>[0-9]+)\]')

def mkd(path):
    try:
        pathlib.Path(path).mkdir()
    except FileExistsError:
        pass

def extract_timestamp(line):
    m = timestamp_regex.match(line)
    if m is None:
        raise Exception("failed to parse timestamp from line `" + line + "`")
    return int(m.group("ts"))

def read_log_file(path):
    try:
        with open(path, 'r') as f:
            contents = f.readlines()

        matches = ['start #', 'stop #']
        times = []
        time = []
        for line in contents:
            if not any(map(lambda m: m in line, matches)):
                continue
            t = extract_timestamp(line)
            time.append(t)
            if len(time) == 2:
                times.append(time)
                time = []
        return times
    except IOError as e:
        print(e)
        sys.exit(1)

def extract_mean(log):
    times = [t[1] - t[0] for t in log]
    return [statistics.mean(times), np.std(np.array(times))]

def plot(title, data, plot_output_path):
    labels = sorted(data.keys())
    jvm_means = []
    svm_means = []
    for label in labels:
        jvm_means.append(round(data[label][0][0]/1000, 1))
        svm_means.append(round(data[label][1][0]/1000, 1))

    fig, ax = plt.subplots()
    fig.set_size_inches(20, 6)
    fig.set_dpi(100)

    x = np.arange(len(labels))
    width = 0.5  # the width of the bars
    rects1 = ax.bar(x - width/2, jvm_means, width, label='JVM')
    rects2 = ax.bar(x + width/2, svm_means, width, label='SVM')

    ax.set_ylabel('t (us)')
    ax.set_title(title)
    ax.set_xticks(x, labels)
    ax.legend()

    ax.bar_label(rects1, padding=3)
    ax.bar_label(rects2, padding=3)

    fig.tight_layout()

    mkd(plot_output_path)
    save_path = os.path.join(plot_output_path, 'plot.png')
    print("saving plot to", save_path)
    plt.savefig(save_path)
    plt.close(fig)

def plot_one(title, data, plot_output_path, tag):
    y = [t[1] - t[0] for t in data][::1000]
    labels = range(1, len(y) + 1)

    fig, ax = plt.subplots()

    x = np.arange(len(labels))
    width = 0.2  # the width of the bars
    rects1 = ax.bar(x - width/2, y, width)

    ax.set_ylabel('t (us)')    
    ax.set_title(f'{title}_{tag}')

    fig.tight_layout()

    mkd(plot_output_path)
    save_path = os.path.join(plot_output_path, f'plot_{tag}.png')
    print("saving plot to", save_path)
    plt.savefig(save_path)
    plt.close(fig)


def plot_dir(dir):
    print('processing: ' + dir)

    dir_basename = os.path.basename(os.path.normpath(dir))
    plot_output_path = os.path.join('plots', dir_basename)

    data = {}
    for test_dir in os.listdir(dir):
        test_dir_path = os.path.join(dir, test_dir)
        print('processing: ' + test_dir_path)
        jvm_log = read_log_file(os.path.join(test_dir_path, 'jvm.log'))
        svm_log = read_log_file(os.path.join(test_dir_path, 'svm.log'))
        plot_one(dir_basename, jvm_log, plot_output_path, f'{test_dir}_jvm')
        plot_one(dir_basename, svm_log, plot_output_path, f'{test_dir}_svm')
        jvm_mean = extract_mean(jvm_log)
        svm_mean = extract_mean(svm_log)
        data[test_dir] = (jvm_mean, svm_mean)

    plot(dir_basename, data, plot_output_path)

if __name__ == "__main__":

    if len(sys.argv) < 2:
        print(f"usage: {sys.argv[0]} log_dir")
        sys.exit(1)
    
    try:
        shutil.rmtree('plots')
    except IOError:
        pass
    mkd('plots')

    for dir in sys.argv[1:]:
        plot_dir(dir)

