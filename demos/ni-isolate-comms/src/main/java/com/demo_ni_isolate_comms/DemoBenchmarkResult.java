package com.demo_ni_isolate_comms;

import java.util.Arrays;

public final class DemoBenchmarkResult {
    private final long[] times;
    private final long max;
    private final long min;
    private final double avg;
    private final long[] sortedTimes;
    private final long sortedMax;
    private final long sortedMin;
    private final double sortedAvg;

    public DemoBenchmarkResult(long[] times) {
        this.times = times;
        this.min = Arrays.stream(times).min().orElse(0);
        this.max = Arrays.stream(times).max().orElse(0);
        this.avg = Arrays.stream(times).average().orElse(0);

        int cutoff = times.length / 100;
        long[] timesCopy = Arrays.copyOf(this.times, this.times.length);
        Arrays.sort(timesCopy);
        this.sortedTimes = Arrays.copyOfRange(timesCopy, cutoff, times.length - cutoff);
        this.sortedMin = this.sortedTimes[0];
        this.sortedMax = this.sortedTimes[this.sortedTimes.length - 1];
        this.sortedAvg = Arrays.stream(times).average().orElse(0);
    }

    public long[] getTimes() {
        return times;
    }

    public long getMax() {
        return max;
    }

    public long getMin() {
        return min;
    }

    public double getAvg() {
        return avg;
    }

    public long[] getSortedTimes() {
        return sortedTimes;
    }

    public long getSortedMax() {
        return sortedMax;
    }

    public long getSortedMin() {
        return sortedMin;
    }

    public double getSortedAvg() {
        return sortedAvg;
    }
}
