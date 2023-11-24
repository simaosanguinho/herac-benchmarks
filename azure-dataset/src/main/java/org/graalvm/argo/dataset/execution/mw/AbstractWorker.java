package org.graalvm.argo.dataset.execution.mw;

import java.io.IOException;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;

public abstract class AbstractWorker {

    protected final Set<String> owners;
    protected final Set<String> functions;
    private final int maxAllowedMemory;

    protected int totalRequests = 0;
    protected int maxExperiencedMemoryUtilization = 0;

    protected AtomicInteger memoryUtilization;

    protected AbstractWorker(int maxAllowedMemory) {
        this.owners = new HashSet<>();
        this.functions = new HashSet<>();
        this.maxAllowedMemory = maxAllowedMemory;
        this.memoryUtilization = new AtomicInteger(0);
    }

    public abstract void ensureUploaded(String owner, String function);

    public abstract void acceptFunctionInvocation(String owner, String function, int allocatedMemoryMb, int duration, int timestamp) throws IOException;

    public boolean hasFunctionRegistered(String function) {
        return functions.contains(function);
    }

    public boolean hasOwnerRegistered(String owner) {
        return owners.contains(owner);
    }

    public int getCurrentMemoryUtilization() {
        return memoryUtilization.get();
    }

    public boolean canAccommodateRequest(int invocationMemory) {
        return memoryUtilization.get() + invocationMemory <= maxAllowedMemory;
    }

    public void printStatistics() {
        System.out.println("###################################");
        System.out.println("Registered functions: " + functions.size());
        System.out.println("Registered owners:    " + owners.size());
        System.out.println("Total requests:       " + totalRequests);
        System.out.println("Max memory:           " + maxExperiencedMemoryUtilization);
        System.out.println("###################################");
    }
}
