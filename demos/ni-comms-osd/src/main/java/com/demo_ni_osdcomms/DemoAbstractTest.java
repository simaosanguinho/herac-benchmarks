package com.demo_ni_osdcomms;

public abstract class DemoAbstractTest {

    protected long[] start;
    protected long[] stop;
    protected DemoSerializer json;

    protected abstract void printResults(int warmupRuns, int runs);

    public abstract void gson(int bufSize, int runs, int warmupRuns);

    public abstract void jackson(int bufSize, int runs, int warmupRuns);

    public abstract void kryo(int bufSize, int runs, int warmupRuns);
}
