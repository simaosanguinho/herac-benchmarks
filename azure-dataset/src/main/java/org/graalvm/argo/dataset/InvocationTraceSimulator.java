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

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

/**
 * This class loads an invocation trace and replays each invocation, one at a
 * time. Periodically, it will generate information regarding the number of
 * users, functions, and invocations that would be active on a real platform.
 */
public class InvocationTraceSimulator {

    private static final String AGGREGATED_INVOCATION_DATA = "%d %d %d %d %d %d %d %d";
    private static final List<Invocation> INVOCATIONS = new LinkedList<>();

    private static Options prepareOptions() {
        Options options = new Options();
        Option input = new Option("i", "input", true, "Input invocation trace file path.");
        input.setRequired(true);
        options.addOption(input);
        Option output = new Option("o", "output", true, "Output file path.");
        output.setRequired(true);
        options.addOption(output);
        Option keepalive = new Option("k", "keealive", true, "Function keep alive time.");
        keepalive.setRequired(false);
        options.addOption(keepalive);
        return options;
    }

    public static void main(String[] args) throws Exception {
        Options options = prepareOptions();
        try {
            CommandLine cmd = new DefaultParser().parse(options, args);
            String inputFile = cmd.getOptionValue("input");
            String outputFile = cmd.getOptionValue("output");
            int keepAlive = Integer.parseInt(cmd.getOptionValue("keepalive", "0"));
            loadInvocations(inputFile, outputFile, keepAlive);
            simulateInvocations(outputFile, keepAlive);
        } catch (ParseException e) {
            System.out.println(e.getMessage());
            new HelpFormatter().printHelp("utility-name", options);
            return;
        }
    }

    private static void loadInvocations(String invocationsFile, String outputFile, int keepAlive) throws Exception {
        try (BufferedReader br = new BufferedReader(new FileReader(invocationsFile))) {
            String line;
            String[] splitRow;
            br.readLine(); // To skip the header
            while ((line = br.readLine()) != null) {
                splitRow = line.split(InvocationTraceGenerator.DELIMITER);
                INVOCATIONS.add(new Invocation(splitRow[0], splitRow[1], Integer.valueOf(splitRow[2]), Integer.valueOf(splitRow[3]), Integer.valueOf(splitRow[4])));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void simulateInvocations(String filename, int keepAlive) throws Exception {
        Set<Invocation> activeInvocations = new HashSet<>();
        List<String> aggregatedInvocationData = new LinkedList<>();
        int lastTimestamp = 0;
        System.out.println("Simulating trace with " + INVOCATIONS.size() + " invocations");
        int invocationsProcessed = 0;

        for (Invocation currentInvocation : INVOCATIONS) {
            int currentInvocationTimestamp = currentInvocation.getTimestamp();
            activeInvocations.removeIf(f -> currentInvocationTimestamp >= f.getEndTimestamp() + keepAlive);
            activeInvocations.add(currentInvocation);

            if (currentInvocationTimestamp - lastTimestamp > 1000) {
                /* Gather aggregated invocation data for plot at most once per second.*/
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

                aggregatedInvocationData.add(String.format(AGGREGATED_INVOCATION_DATA, currentInvocationTimestamp, runningUsers, runningFunctions, cachedUsers, cachedFunctions, runningInvocations, runningInvocationsFootprint, cachedInvocationsFootprint));
                lastTimestamp = currentInvocationTimestamp;
            }

            if (invocationsProcessed % 10000 == 0) {
                System.out.println(invocationsProcessed);
            }
            ++invocationsProcessed;
        }
        Files.write(Paths.get("output", filename), aggregatedInvocationData, StandardCharsets.UTF_8);
    }
}
