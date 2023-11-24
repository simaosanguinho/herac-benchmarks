package org.graalvm.argo.dataset.execution.mw;

public class FakeWorker extends AbstractWorker {

    public FakeWorker(int maxAllowedMemory) {
        super(maxAllowedMemory);
    }

    public void ensureUploaded(String owner, String function) {
        if (!functions.contains(function)) {
            owners.add(owner);
            functions.add(function);
        }
    }

    @Override
    public void acceptFunctionInvocation(String owner, String function, int allocatedMemoryMb, int duration, int timestamp) {
        int currentMemoryUtilization = memoryUtilization.addAndGet(allocatedMemoryMb);
        MockNetworkUtils.sendPost(new InvocationCallback(this, allocatedMemoryMb, duration));

        if (currentMemoryUtilization > maxExperiencedMemoryUtilization) {
            maxExperiencedMemoryUtilization = currentMemoryUtilization;
        }
        ++totalRequests;
    }

    private static class InvocationCallback implements Runnable {

        private final AbstractWorker worker;
        private final int invocationMemory;
        private final int duration;

        private InvocationCallback(AbstractWorker worker, int invocationMemory, int duration) {
            this.worker = worker;
            this.invocationMemory = invocationMemory;
            this.duration = duration;
        }

        @Override
        public void run() {
            try {
                Thread.sleep(duration);
            } catch (InterruptedException e) {
            }
            worker.memoryUtilization.addAndGet(-invocationMemory);
        }

    }
}
