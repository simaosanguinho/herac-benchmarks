package org.graalvm.argo.dataset.execution.mw;

import java.util.Comparator;
import java.util.Iterator;
import java.util.TreeSet;

public class FakeWorker extends AbstractWorker {

    /**
     * The first element of the int array is the end timestamp,
     * and the second element is the allocated memory value.
     */
    private final TreeSet<int[]> activeInvocations;

    public FakeWorker(int maxAllowedMemory) {
        super(maxAllowedMemory);
        /* Compare by end timestamp. */
        this.activeInvocations = new TreeSet<>(Comparator.comparingInt(a -> a[0]));
    }

    public void ensureUploaded(String owner, String function) {
        if (!functions.contains(function)) {
            owners.add(owner);
            functions.add(function);
        }
    }

    @Override
    public void acceptFunctionInvocation(String owner, String function, int allocatedMemoryMb, int duration, int timestamp) {
        evictTimedOutInvocations(timestamp);
        activeInvocations.add(new int[] {timestamp + duration, allocatedMemoryMb});
        int currentMemoryUtilization = memoryUtilization.addAndGet(allocatedMemoryMb);

        int currConc = activeInvocations.size();
        if (currConc > maxExperiencedConcurrency) {
            maxExperiencedConcurrency = currConc;
        }
        if (currentMemoryUtilization > maxExperiencedMemoryUtilization) {
            maxExperiencedMemoryUtilization = currentMemoryUtilization;
        }

        ++totalRequests;
    }

    private void evictTimedOutInvocations(int currentTimestamp) {
        Iterator<int[]> itr = activeInvocations.iterator();
        while (itr.hasNext()) {
            int[] invocationRecord = itr.next();
            if (currentTimestamp >= invocationRecord[0]) {
                memoryUtilization.addAndGet(-invocationRecord[1]);
                itr.remove();
            } else {
                break;
            }
        }
    }
}
