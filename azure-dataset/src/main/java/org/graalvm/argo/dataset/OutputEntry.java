package org.graalvm.argo.dataset;

public class OutputEntry {

    // Current timestamp (when the output entry is produced).
    protected int timestamp;
    // Invocations processed since the last output entry.
    protected int invocationsProcessed;
    // Cold starts since the last output entry.
    protected int coldStarts;
    // Current number of users, functions, invocations, and invocation footprint (MBs).
    protected int runningUsers;
    protected int runningFunctions;
    protected int runningInvocations;
    protected int runningInvocationsFootprint;
    // Number of cached users, functions, and invocation footprint (MBs).
    protected int cachedUsers;
    protected int cachedFunctions;
    protected int cachedInvocationsFootprint;

    public OutputEntry(
            int timestamp,
            int invocationsProcessed,
            int coldStarts,
            int runningUsers,
            int runningFunctions,
            int runningInvocations,
            int runningInvocationsFootprint,
            int cachedUsers,
            int cachedFunctions,
            int cachedInvocationsFootprint) {
        this.timestamp = timestamp;
        this.invocationsProcessed = invocationsProcessed;
        this.coldStarts = coldStarts;
        this.runningUsers = runningUsers;
        this.runningFunctions = runningFunctions;
        this.runningInvocations = runningInvocations;
        this.runningInvocationsFootprint = runningInvocationsFootprint;
        this.cachedUsers = cachedUsers;
        this.cachedFunctions = cachedFunctions;
        this.cachedInvocationsFootprint = cachedInvocationsFootprint;
    }

    public static String toString(
            int timestamp,
            int invocationsProcessed,
            int coldStarts,
            int runningUsers,
            int runningFunctions,
            int runningInvocations,
            int runningInvocationsFootprint,
            int cachedUsers,
            int cachedFunctions,
            int cachedInvocationsFootprint) {
        return String.format("time %s; invocations %s cold %s; running users %s functions %s invocations %s footprint %s; cached users %s functions %s footprint %s",
                timestamp, invocationsProcessed, coldStarts, runningUsers, runningFunctions, runningInvocations, runningInvocationsFootprint, cachedUsers, cachedFunctions, cachedInvocationsFootprint);
    }

    @Override
    public String toString() {
        return toString(timestamp, invocationsProcessed, coldStarts, runningUsers, runningFunctions, runningInvocations, runningInvocationsFootprint, cachedUsers, cachedFunctions, cachedInvocationsFootprint);
    }
}
