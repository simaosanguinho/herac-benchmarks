package org.graalvm.argo.dataset;

public class Invocation {
    private final String owner;
    private final String function;
    private final int memory;
    private final int duration;
    private final int timestamp;
    private final int endTimestamp;

    public Invocation(String owner, String function, int memory, int duration, int timestamp) {
        this.owner = owner;
        this.function = function;
        this.memory = memory;
        this.duration = duration;
        this.timestamp = timestamp;
        this.endTimestamp = timestamp + duration;
    }

    public String getOwner() {
        return owner;
    }

    public String getFunction() {
        return function;
    }

    public int getMemory() {
        return memory;
    }

    public int getDuration() {
        return duration;
    }

    public int getTimestamp() {
        return timestamp;
    }

    public int getEndTimestamp() {
        return endTimestamp;
    }

    @Override
    public String toString() {
        return String.format("%s,%s,%d,%d,%d", owner, function, memory, duration, timestamp);
    }
}
