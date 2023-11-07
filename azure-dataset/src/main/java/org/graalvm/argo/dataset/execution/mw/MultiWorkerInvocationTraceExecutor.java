package org.graalvm.argo.dataset.execution.mw;

import org.graalvm.argo.dataset.InvocationTraceGenerator;
import org.graalvm.argo.dataset.execution.ExecutorConfiguration;
import org.graalvm.argo.dataset.execution.InvocationTraceExecutor;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.Arrays;
import java.util.Comparator;

public class MultiWorkerInvocationTraceExecutor extends InvocationTraceExecutor {

    private final static int WORKER_COUNT = 80;

    private final AbstractWorker[] workers;

    public MultiWorkerInvocationTraceExecutor(ExecutorConfiguration config) {
        super(config);
        workers = new AbstractWorker[WORKER_COUNT];
//        workers[0] = new RealWorker(this);
        for (int i = 0; i < WORKER_COUNT; ++i) {
            workers[i] = new FakeWorker();
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

                AbstractWorker worker = schedule(owner, function);
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
    }

    private AbstractWorker schedule(String owner, String function) {
        AbstractWorker result = null;
        for (AbstractWorker w : workers) {
            if (w.hasFunctionRegistered(function)) {
                result = w;
                break;
            }
        }
        if (result == null) {
            for (AbstractWorker w : workers) {
                if (w.hasOwnerRegistered(owner)) {
                    result = w;
                    break;
                }
            }
        }
        if (result == null) {
            Arrays.sort(workers, Comparator.comparing(AbstractWorker::getCurrentMemoryUtilization));
            result = workers[0];
        }
        return result;
    }
}
