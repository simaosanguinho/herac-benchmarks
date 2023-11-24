package org.graalvm.argo.dataset.execution.mw;

import org.graalvm.argo.dataset.InvocationTraceGenerator;
import org.graalvm.argo.dataset.execution.ExecutorConfiguration;
import org.graalvm.argo.dataset.execution.InvocationTraceExecutor;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;

public class MultiWorkerInvocationTraceExecutor extends InvocationTraceExecutor {

    private final static int WORKER_COUNT = 100;
    private final static int MAX_MEMORY_PER_WORKER_MB = 98304;

    private final AbstractWorker[] workers;
    private int overalloc = 0;
    private final static int REAL_WORKER_INDEX = 95;
    private final static String REAL_WORKER_TRACE_OUTPUT = "/tmp/lse_trace.csv";

    public MultiWorkerInvocationTraceExecutor(ExecutorConfiguration config) {
        super(config);
        workers = new AbstractWorker[WORKER_COUNT];
        for (int i = 0; i < WORKER_COUNT; ++i) {
            workers[i] = new FakeWorker(MAX_MEMORY_PER_WORKER_MB);
        }
        insertRealWorker();
    }

    private void insertRealWorker() {
        try {
            File outputTraceFile = new File(REAL_WORKER_TRACE_OUTPUT);
            outputTraceFile.createNewFile();
            workers[REAL_WORKER_INDEX] = new RealWorker(MAX_MEMORY_PER_WORKER_MB, this, outputTraceFile);
        } catch (IOException e) {
            System.err.println("Couldn't create a real worker: " + e.getMessage());
        }
    }

    @Override
    public void execute(String invocationsFilePath) {
        try (BufferedReader br = new BufferedReader(new FileReader(invocationsFilePath))) {
            String line;
            String[] splitRow;
            br.readLine(); // To skip the header
            int currentTimestamp = 0;
            while ((line = br.readLine()) != null) {
                splitRow = line.split(InvocationTraceGenerator.DELIMITER);
                String owner = splitRow[0];
                String function = splitRow[1];
                int allocatedMemoryMb = Integer.parseInt(splitRow[2]);
                int duration = Integer.parseInt(splitRow[3]);
                int timestamp = Integer.parseInt(splitRow[4]);

                AbstractWorker worker = schedule(owner, function, allocatedMemoryMb);
                worker.ensureUploaded(owner, function);
                waitForInvocation(currentTimestamp, timestamp);
                currentTimestamp = timestamp;

                worker.acceptFunctionInvocation(owner, function, allocatedMemoryMb, duration, timestamp);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        for (AbstractWorker w : workers) {
            w.printStatistics();
        }
        System.out.println("Overallocated " + overalloc + " requests.");
        System.out.println("Real node stats:");
        workers[REAL_WORKER_INDEX].printStatistics();
        if (workers[REAL_WORKER_INDEX] instanceof RealWorker) {
            ((RealWorker) workers[REAL_WORKER_INDEX]).close();
        }
        MockNetworkUtils.shutdown();
    }

    private AbstractWorker schedule(String owner, String function, int invocationMemory) {
        AbstractWorker result = null;
        for (AbstractWorker w : workers) {
            if (w.canAccommodateRequest(invocationMemory) && w.hasFunctionRegistered(function)) {
                result = w;
                break;
            }
        }
        if (result == null) {
            for (AbstractWorker w : workers) {
                if (w.canAccommodateRequest(invocationMemory) && w.hasOwnerRegistered(owner)) {
                    result = w;
                    break;
                }
            }
        }
        if (result == null) {
            result = findLeastUtilized();
            if (!result.canAccommodateRequest(invocationMemory)) {
                overalloc++;
            }
        }
        return result;
    }

    private AbstractWorker findLeastUtilized() {
        AbstractWorker result = workers[0];
        for (int i = 1; i < workers.length; ++i) {
            if (workers[i].getCurrentMemoryUtilization() < result.getCurrentMemoryUtilization()) {
                result = workers[i];
            }
        }
        return result;
    }
}
