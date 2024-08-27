package org.graalvm.argo.dataset.execution.mw;

import org.graalvm.argo.dataset.execution.mw.memory.AbstractMemoryManager;
import org.graalvm.argo.dataset.multilang.FunctionLanguage;

import java.util.function.Consumer;

public class PhysicalFakeWorker extends AbstractWorker {

    private final MultiWorkerInvocationTraceExecutor executor;
    private final String address;

    protected PhysicalFakeWorker(AbstractMemoryManager memoryManager, MultiWorkerInvocationTraceExecutor executor, String address) {
        super(memoryManager);
        this.executor = executor;
        this.address = address;
    }

    @Override
    public void ensureUploaded(String owner, String function, FunctionLanguage language, int functionId) {
        if (!functions.contains(owner + "_" + function)) {
            executor.uploadFunction(address, owner, function, language, functionId);
            owners.add(owner);
            functions.add(owner + "_" + function);
        }
    }

    @Override
    public void acceptFunctionInvocation(String owner, String function, int functionMemory, int duration, int timestamp, FunctionLanguage language, int functionId) {
        memoryManager.startRequest(owner, function, functionMemory);
        executor.invokeFunction(address, owner, function, timestamp, duration, language, functionId, new InvocationCallback(this, owner, function));
        ++totalRequests;
    }

    private static class InvocationCallback implements Consumer<String> {

        private final AbstractWorker worker;
        private final String owner;
        private final String function;

        private InvocationCallback(AbstractWorker worker, String owner, String function) {
            this.worker = worker;
            this.owner = owner;
            this.function = function;
        }

        @Override
        public void accept(String s) {
            worker.memoryManager.finishRequest(owner, function);
        }
    }
}
