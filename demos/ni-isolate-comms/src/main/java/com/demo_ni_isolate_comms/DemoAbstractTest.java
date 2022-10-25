package com.demo_ni_isolate_comms;

public abstract class DemoAbstractTest {

    public void net1_32B(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(32, bufSize, runs, warmupRuns);
    }

    public void net2_64B(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(64, bufSize, runs, warmupRuns);
    }

    public void net3_128B(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(128, bufSize, runs, warmupRuns);
    }

    public void net4_256B(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(256, bufSize, runs, warmupRuns);
    }

    public void net5_512B(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(512, bufSize, runs, warmupRuns);
    }

    public void net6_1KB(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(1024, bufSize, runs, warmupRuns);
    }

    public void net7_10KB(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(10*1024, bufSize, runs, warmupRuns);
    }

    public void net8_100KB(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(100*1024, bufSize, runs, warmupRuns);
    }

    public void net9_1MB(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(1024*1024, bufSize, runs, warmupRuns);
    }

    protected abstract void networkCommsTest(int size, int bufSize, int runs, int warmupRuns);
}
