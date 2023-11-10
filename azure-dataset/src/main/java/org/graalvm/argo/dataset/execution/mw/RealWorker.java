package org.graalvm.argo.dataset.execution.mw;

import java.util.function.Consumer;

public class RealWorker extends AbstractWorker {

    private final MultiWorkerInvocationTraceExecutor executor;

    protected RealWorker(int maxAllowedMemory, MultiWorkerInvocationTraceExecutor executor) {
        super(maxAllowedMemory);
        this.executor = executor;
    }

    public void ensureUploaded(String owner, String function) {
        if (!functions.contains(function)) {
            executor.uploadFunction(owner, function);
            owners.add(owner);
            functions.add(function);
        }
    }

    @Override
    public void acceptFunctionInvocation(String owner, String function, int allocatedMemoryMb, int duration, int timestamp) {
        executor.invokeFunction(owner, function, allocatedMemoryMb, duration, timestamp, new InvocationCallback(this, allocatedMemoryMb));
        int currentMemoryUtilization = memoryUtilization.addAndGet(allocatedMemoryMb);

        if (currentMemoryUtilization > maxExperiencedMemoryUtilization) {
            maxExperiencedMemoryUtilization = currentMemoryUtilization;
        }
        ++totalRequests;
    }

    private static class InvocationCallback implements Consumer<String> {

        private final AbstractWorker worker;
        private final int invocationMemory;

        private InvocationCallback(AbstractWorker worker, int invocationMemory) {
            this.worker = worker;
            this.invocationMemory = invocationMemory;
        }

        @Override
        public void accept(String s) {
            worker.memoryUtilization.addAndGet(-invocationMemory);
        }
    }
}
