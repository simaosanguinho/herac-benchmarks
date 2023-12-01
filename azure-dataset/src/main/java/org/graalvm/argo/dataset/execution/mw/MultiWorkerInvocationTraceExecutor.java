package org.graalvm.argo.dataset.execution.mw;

import org.graalvm.argo.dataset.InvocationTraceGenerator;
import org.graalvm.argo.dataset.execution.ExecutorConfiguration;
import org.graalvm.argo.dataset.execution.InvocationTraceExecutor;
import org.graalvm.argo.dataset.execution.mw.memory.MemoryManagerFactories.AbstractMemoryManagerFactory;
import org.graalvm.argo.dataset.execution.mw.memory.MemoryManagerFactories.SingleInvocationMemoryManagerFactory;
import org.graalvm.argo.dataset.execution.mw.memory.MemoryManagerFactories.OwnerCollocationMemoryManagerFactory;
import org.graalvm.argo.dataset.execution.mw.memory.MemoryManagerFactories.SingleFunctionMemoryManagerFactory;
import org.graalvm.argo.dataset.multilang.FunctionLanguage;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;

import static org.graalvm.argo.dataset.execution.Environment.WORKER_COUNT;
import static org.graalvm.argo.dataset.execution.Environment.REAL_WORKER_INDEX;
import static org.graalvm.argo.dataset.execution.Environment.REAL_WORKER_TRACE_OUTPUT;

public class MultiWorkerInvocationTraceExecutor extends InvocationTraceExecutor {

    private final AbstractWorker[] workers;
    private int overalloc = 0;

    public MultiWorkerInvocationTraceExecutor(ExecutorConfiguration config) {
        super(config);
        AbstractMemoryManagerFactory factory = getMemoryManagerFactory(config);
        workers = new AbstractWorker[WORKER_COUNT];
        for (int i = 0; i < WORKER_COUNT; ++i) {
            workers[i] = new FakeWorker(factory.createMemoryManager());
        }
        insertRealWorker(factory);
    }

    private AbstractMemoryManagerFactory getMemoryManagerFactory(ExecutorConfiguration config) {
        if (Boolean.TRUE.equals(config.invocationCollocation)) {
            if (Boolean.TRUE.equals(config.functionIsolation)) {
                return new SingleFunctionMemoryManagerFactory();
            } else {
                return new OwnerCollocationMemoryManagerFactory();
            }
        } else {
            return new SingleInvocationMemoryManagerFactory();
        }
    }

    private void insertRealWorker(AbstractMemoryManagerFactory factory) {
        try {
            File outputTraceFile = new File(REAL_WORKER_TRACE_OUTPUT);
            outputTraceFile.createNewFile();
            workers[REAL_WORKER_INDEX] = new RealWorker(factory.createMemoryManager(), this, outputTraceFile);
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
                int duration = Integer.parseInt(splitRow[3]);
                int timestamp = Integer.parseInt(splitRow[4]);
                FunctionLanguage language = FunctionLanguage.fromString(splitRow[5]);
                int functionMemory = config.getFunctionConfiguration(language).memory;

                AbstractWorker worker = schedule(owner, function, functionMemory);
                worker.ensureUploaded(owner, function, language);
                waitForInvocation(currentTimestamp, timestamp);
                currentTimestamp = timestamp;

                worker.acceptFunctionInvocation(owner, function, functionMemory, duration, timestamp, language);
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
            if (w.canAccommodateRequest(owner, function, invocationMemory) && w.hasFunctionRegistered(function)) {
                result = w;
                break;
            }
        }
        if (result == null) {
            for (AbstractWorker w : workers) {
                if (w.canAccommodateRequest(owner, function, invocationMemory) && w.hasOwnerRegistered(owner)) {
                    result = w;
                    break;
                }
            }
        }
        if (result == null) {
            result = findLeastUtilized();
            if (!result.canAccommodateRequest(owner, function, invocationMemory)) {
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
