package org.graalvm.argo.dataset.execution.mw;

import org.graalvm.argo.dataset.execution.mw.memory.AbstractMemoryManager;
import org.graalvm.argo.dataset.multilang.FunctionLanguage;

public class FakeWorker extends AbstractWorker {

    public FakeWorker(AbstractMemoryManager memoryManager) {
        super(memoryManager);
    }

    @Override
    public void ensureUploaded(String owner, String function, FunctionLanguage language, int functionId) {
        if (!functions.contains(owner + "_" + function)) {
            owners.add(owner);
            functions.add(owner + "_" + function);
        }
    }

    @Override
    public void acceptFunctionInvocation(String owner, String function, int functionMemory, int duration, int timestamp, FunctionLanguage language, int functionId) {
        memoryManager.startRequest(owner, function, functionMemory);
        MockNetworkUtils.sendPost(new InvocationCallback(this, owner, function, duration));

        ++totalRequests;
    }

    private static class InvocationCallback implements Runnable {

        private final AbstractWorker worker;
        private final String owner;
        private final String function;
        private final int duration;

        private InvocationCallback(AbstractWorker worker, String owner, String function, int duration) {
            this.worker = worker;
            this.owner = owner;
            this.function = function;
            this.duration = duration;
        }

        @Override
        public void run() {
            try {
                Thread.sleep(duration);
            } catch (InterruptedException e) {
            }
            worker.memoryManager.finishRequest(owner, function);
        }

    }
}
