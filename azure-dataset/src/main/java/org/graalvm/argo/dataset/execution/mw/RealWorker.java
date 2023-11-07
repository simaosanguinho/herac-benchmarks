package org.graalvm.argo.dataset.execution.mw;

public class RealWorker extends AbstractWorker {

    private final MultiWorkerInvocationTraceExecutor executor;

    protected RealWorker(MultiWorkerInvocationTraceExecutor executor) {
        super();
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
        super.acceptFunctionInvocation(owner, function, allocatedMemoryMb, duration, timestamp);
        executor.invokeFunction(owner, function, allocatedMemoryMb, duration, timestamp);
    }
}
