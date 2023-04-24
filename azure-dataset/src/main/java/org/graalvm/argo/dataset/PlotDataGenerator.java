package org.graalvm.argo.dataset;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;

// TODO - we need a better name :-)
public class PlotDataGenerator {

    private static final String AGGREGATED_INVOCATION_DATA = "%d %d %d %d %d %d %d %d";

    public static void main(String[] args) throws Exception {
        String invocationsFile = args[0];
        String outputFile = args[1];
        int keepAlive = 0;
        if (args.length > 2) {
            keepAlive = Integer.valueOf(args[2]);
        }
        process(invocationsFile, outputFile, keepAlive);
    }

    private static void process(String invocationsFile, String outputFile, int keepAlive) throws Exception {
        List<Invocation> invocations = new LinkedList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(invocationsFile))) {
            String line;
            String[] splitRow;
            br.readLine(); // To skip the header
            while ((line = br.readLine()) != null) {
                splitRow = line.split(DatasetProcessor.DELIMITER);
                invocations.add(new Invocation(splitRow[0], splitRow[1], Integer.valueOf(splitRow[2]), Integer.valueOf(splitRow[3]), Integer.valueOf(splitRow[4])));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        simulateTrace(invocations, outputFile, keepAlive);
    }

    private static void simulateTrace(List<Invocation> invocations, String filename, int keepAlive) throws Exception {
        Set<Invocation> activeInvocations = new HashSet<>();
        List<String> aggregatedInvocationData = new LinkedList<>();
        System.out.println("Simulating trace with " + invocations.size() + " invocations");
        int invocationsProcessed = 0;

        for (Invocation currentInvocation : invocations) {
            int currentInvocationTimestamp = currentInvocation.getTimestamp();
            activeInvocations.removeIf(f -> currentInvocationTimestamp >= f.getEndTimestamp() + keepAlive);
            activeInvocations.add(currentInvocation);
            /* gather aggregated invocation data for plot */
            long runningUsers = activeInvocations.parallelStream().filter(i -> i.getEndTimestamp() > currentInvocationTimestamp).map(Invocation::getOwner).distinct().count();
            long runningFunctions  = activeInvocations.parallelStream().filter(i -> i.getEndTimestamp() > currentInvocationTimestamp).map(Invocation::getFunction).distinct().count();
            long runningInvocations = activeInvocations.parallelStream().filter(i -> i.getEndTimestamp() > currentInvocationTimestamp).count();
            long runningInvocationsFootprint = activeInvocations.parallelStream().filter(i -> i.getEndTimestamp() > currentInvocationTimestamp).mapToInt(Invocation::getMemory).sum();

            long totalUsers = activeInvocations.parallelStream().map(Invocation::getOwner).distinct().count();
            long totalFunctions = activeInvocations.parallelStream().map(Invocation::getFunction).distinct().count();

            long cachedUsers = totalUsers - runningUsers;
            long cachedFunctions = totalFunctions - runningFunctions;
            // To calculate the size of our cache we are assuming that we can assume that we only keep one lambda live for each function.
            // Then, we multiply the avg footprint of each function and we sum. The result is an estimate of our cache footprint.
            long cachedInvocationsFootprint = cachedFunctions * 125; // TODO - we need to fix this. 125 is the avg of all functions...

            // TODO - why not writing to disk directly? This will accumulate more and more memory.
            aggregatedInvocationData.add(String.format(AGGREGATED_INVOCATION_DATA, currentInvocationTimestamp, runningUsers, runningFunctions, cachedUsers, cachedFunctions, runningInvocations, runningInvocationsFootprint, cachedInvocationsFootprint));
            if (invocationsProcessed % 10000 == 0) {
                System.out.println(invocationsProcessed);
            }
            ++invocationsProcessed;
        }
        Files.write(Paths.get("output", filename), aggregatedInvocationData, StandardCharsets.UTF_8);
    }
}
