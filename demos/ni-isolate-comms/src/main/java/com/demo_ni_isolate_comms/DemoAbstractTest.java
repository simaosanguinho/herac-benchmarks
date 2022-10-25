package com.demo_ni_isolate_comms;

public abstract class DemoAbstractTest {

    public void network32B(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(32, bufSize, runs, warmupRuns);
    }

    public void network64B(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(64, bufSize, runs, warmupRuns);
    }

    public void network128B(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(128, bufSize, runs, warmupRuns);
    }

    public void network256B(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(256, bufSize, runs, warmupRuns);
    }

    public void network512B(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(512, bufSize, runs, warmupRuns);
    }

    public void network1KB(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(1024, bufSize, runs, warmupRuns);
    }

    public void network10KB(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(10*1024, bufSize, runs, warmupRuns);
    }

    public void network100KB(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(100*1024, bufSize, runs, warmupRuns);
    }

    public void network1MB(int bufSize, int runs, int warmupRuns) {
        networkCommsTest(1024*1024, bufSize, runs, warmupRuns);
    }

    protected abstract void networkCommsTest(int size, int bufSize, int runs, int warmupRuns);
}
