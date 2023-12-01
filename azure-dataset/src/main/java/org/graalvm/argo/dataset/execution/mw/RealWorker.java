package org.graalvm.argo.dataset.execution.mw;

import org.graalvm.argo.dataset.execution.mw.memory.AbstractMemoryManager;
import org.graalvm.argo.dataset.multilang.FunctionLanguage;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.function.Consumer;

public class RealWorker extends AbstractWorker {

    private static final String TRACE_INVOCATION_RECORD = "%s,%s,%d,%d,%d,%s";

    private final MultiWorkerInvocationTraceExecutor executor;

    private final BufferedWriter bw;

    protected RealWorker(AbstractMemoryManager memoryManager, MultiWorkerInvocationTraceExecutor executor, File output) throws IOException {
        super(memoryManager);
        this.bw = new BufferedWriter(new FileWriter(output));
        this.executor = executor;
        bw.write("HashOwner,HashFunction,AverageAllocatedMb,AverageDuration,Timestamp");
        bw.newLine();
    }

    public void ensureUploaded(String owner, String function, FunctionLanguage language) {
        if (!functions.contains(function)) {
            executor.uploadFunction(owner, function, language);
            owners.add(owner);
            functions.add(function);
        }
    }

    @Override
    public void acceptFunctionInvocation(String owner, String function, int functionMemory, int duration, int timestamp, FunctionLanguage language) throws IOException {
        bw.write(String.format(TRACE_INVOCATION_RECORD, owner, function, functionMemory, duration, timestamp, language));
        bw.newLine();
        memoryManager.startRequest(owner, function, functionMemory);
        executor.invokeFunction(owner, function, functionMemory, language, new InvocationCallback(this, owner, function));

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

    public void close() {
        try {
            bw.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
