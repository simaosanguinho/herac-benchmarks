package org.graalvm.argo.dataset.execution.mw;

import java.util.*;

public abstract class AbstractWorker {

    protected final Set<String> owners;
    protected final Set<String> functions;

    int totalRequests = 0;
    int maxConc = 0;
    int maxMem = 0;
    /**
     * The first element of the int array is the end timestamp,
     * and the second element is the allocated memory value.
     */
    private final TreeSet<int[]> activeInvocations;
    private int memoryUtilization;

    protected AbstractWorker() {
        this.owners = new HashSet<>();
        this.functions = new HashSet<>();
        /* Compare by end timestamp. */
        this.activeInvocations = new TreeSet<>(Comparator.comparingInt(a -> a[0]));
        this.memoryUtilization = 0;
    }

    public void ensureUploaded(String owner, String function) {
        if (!functions.contains(function)) {
            owners.add(owner);
            functions.add(function);
        }
    }

    public void acceptFunctionInvocation(String owner, String function, int allocatedMemoryMb, int duration, int timestamp) {
        evictTimedOutInvocations(timestamp);
        activeInvocations.add(new int[] {timestamp + duration, allocatedMemoryMb});
        memoryUtilization += allocatedMemoryMb;

        int currConc = activeInvocations.size();
        if (currConc > maxConc) {
            maxConc = currConc;
        }
        if (memoryUtilization > maxMem) {
            maxMem = memoryUtilization;
        }

        ++totalRequests;
    }

    private void evictTimedOutInvocations(int currentTimestamp) {
        Iterator<int[]> itr = activeInvocations.iterator();
        while (itr.hasNext()) {
            int[] invocationRecord = itr.next();
            if (currentTimestamp >= invocationRecord[0]) {
                memoryUtilization -= invocationRecord[1];
                itr.remove();
            } else {
                break;
            }
        }
    }

    public boolean hasFunctionRegistered(String function) {
        return functions.contains(function);
    }

    public boolean hasOwnerRegistered(String owner) {
        return owners.contains(owner);
    }

    public int getCurrentMemoryUtilization() {
        return memoryUtilization;
    }

    public void printStatistics() {
        System.out.println("###################################");
        System.out.println("Registered functions: " + functions.size());
        System.out.println("Registered owners:    " + owners.size());
        System.out.println("Total requests:       " + totalRequests);
        System.out.println("Max memory:           " + maxMem);
        System.out.println("Max concurrency:      " + maxConc);
        System.out.println("###################################");
    }
}
