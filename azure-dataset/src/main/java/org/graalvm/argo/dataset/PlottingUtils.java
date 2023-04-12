package org.graalvm.argo.dataset;

import java.nio.file.Paths;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;

public class PlottingUtils {

    private static final String AGGREGATED_INVOCATION_DATA = "%d %d %d %d";
    private static final int KEEP_ALIVE_MS = 60000;

    public static void printTraceSimulation(List<Invocation> invocations, String filename, boolean includeKeepAlive) {
        simulateTrace(invocations, filename, includeKeepAlive ? KEEP_ALIVE_MS : 0);
    }

    private static void simulateTrace(List<Invocation> invocations, String filename, int keepAlive) {
        Set<Invocation> activeInvocations = new HashSet<>();
        List<String> aggregatedInvocationData = new LinkedList<>();
        System.out.println("Simulating trace with " + invocations.size() + " invocations");
        int n = 0;

        for (Invocation currentInvocation : invocations) {
            int currentInvocationTimestamp = currentInvocation.getTimestamp();
            activeInvocations.removeIf(f -> currentInvocationTimestamp >= f.getEndTimestamp() + keepAlive);
            activeInvocations.add(currentInvocation);
            /* gather aggregated invocation data for plot */
            long activeUsers = activeInvocations.parallelStream().map(Invocation::getOwner).distinct().count();
            long activeFunctions = activeInvocations.parallelStream().map(Invocation::getFunction).distinct().count();
            aggregatedInvocationData.add(String.format(AGGREGATED_INVOCATION_DATA, currentInvocationTimestamp, activeUsers, activeFunctions, activeInvocations.size()));
            if (n % 10000 == 0) {
                System.out.println(n);
            }
            ++n;
        }
        DatasetProcessor.writeToFile(aggregatedInvocationData, Paths.get("output", filename));
    }
}
