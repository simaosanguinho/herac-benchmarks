package org.graalvm.argo.dataset.execution.mw;

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

    protected RealWorker(int maxAllowedMemory, MultiWorkerInvocationTraceExecutor executor, File output) throws IOException {
        super(maxAllowedMemory);
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
    public void acceptFunctionInvocation(String owner, String function, int allocatedMemoryMb, int duration, int timestamp, FunctionLanguage language) throws IOException {
        bw.write(String.format(TRACE_INVOCATION_RECORD, owner, function, allocatedMemoryMb, duration, timestamp, language));
        bw.newLine();
        int currentMemoryUtilization = memoryUtilization.addAndGet(allocatedMemoryMb);
        executor.invokeFunction(owner, function, allocatedMemoryMb, language, new InvocationCallback(this, allocatedMemoryMb));

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

    public void close() {
        try {
            bw.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
