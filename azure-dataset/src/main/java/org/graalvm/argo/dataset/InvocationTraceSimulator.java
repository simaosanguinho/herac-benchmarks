package org.graalvm.argo.dataset;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.TreeSet;
import java.util.stream.Collectors;
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

    /**
     * Minimum number of milliseconds to wait before recalculating aggregated data.
     */
    private static final int SAMPLE_INTERVAL = 1000;

    private static Options prepareOptions() {
        Options options = new Options();
        Option input = new Option("i", "input", true, "Input invocation trace file path.");
        input.setRequired(true);
        options.addOption(input);
        Option keepalive = new Option("k", "keepalive", true, "Function keep alive time in milliseconds.");
        keepalive.setRequired(false);
        options.addOption(keepalive);
        return options;
    }

    public static void main(String[] args) throws Exception {
        Options options = prepareOptions();
        try {
            CommandLine cmd = new DefaultParser().parse(options, args);
            String inputfile = cmd.getOptionValue("input");
            String outputfile = cmd.getOptionValue("output", null);
            int keepalive = Integer.parseInt(cmd.getOptionValue("keepalive", "600000"));
            List<Invocation> invocations = loadInvocations(inputfile, outputfile, keepalive);
            List<OutputEntry> output = simulateInvocations(invocations, keepalive, SAMPLE_INTERVAL);

            for (OutputEntry entry : output) {
                System.out.println(entry);
            }
        } catch (ParseException e) {
            System.err.println(e.getMessage());
            new HelpFormatter().printHelp("utility-name", options);
            return;
        }
    }

    private static List<Invocation> loadInvocations(String invocationsFile, String outputFile, int keepAlive) throws Exception {
        List<Invocation> invocations = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(invocationsFile))) {
            String line;
            String[] splitRow;
            br.readLine(); // To skip the header
            while ((line = br.readLine()) != null) {
                splitRow = line.split(InvocationTraceGenerator.DELIMITER);
                invocations.add(new Invocation(splitRow[0], splitRow[1], Integer.valueOf(splitRow[2]), Integer.valueOf(splitRow[3]), Integer.valueOf(splitRow[4])));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return invocations;
    }

    private static void evictTimedOutInvocations(TreeSet<Invocation> activeInvocations, int timestamp, int keepalive) {
        List<Invocation> evict = new LinkedList<>();
        for (Invocation invocation : activeInvocations) {
            if (timestamp >= invocation.getEndTimestamp() + keepalive) {
                evict.add(invocation);
            } else {
                // The activeInvocations tree is ordered. If we fail the above check, later elements will also fail.
                break;
            }
        }
        activeInvocations.removeAll(evict);
    }

    // TODO - for these, I don't see a clear reason not to doit in a stream.
    private static Invocation findWarmInvocation(TreeSet<Invocation> activeInvocations, int timestamp, String function) {
        for (Invocation invocation : activeInvocations) {
            if (timestamp < invocation.getEndTimestamp()) {
                continue;
            } else if (invocation.getFunction().equals(function)) {
                return invocation;
            }
        }
        return null;
    }

    private static void updateStatistics(
            TreeSet<Invocation> activeInvocations,
            List<OutputEntry> statistics,
            int currentTimestamp,
            int previousTimestamp,
            int lastInvocationsProcessed,
            int coldStarts,
            int invocationsProcessed) {

        List<Invocation> runningInvocations = activeInvocations.parallelStream().filter(i -> i.getEndTimestamp() > currentTimestamp).collect(Collectors.toList());
        int runningUsers = (int) runningInvocations.parallelStream().map(Invocation::getOwner).distinct().count();
        int runningFunctions  = (int) runningInvocations.parallelStream().map(Invocation::getFunction).distinct().count();
        int runningInvocationsFootprint = (int) runningInvocations.parallelStream().mapToInt(Invocation::getMemory).sum();

        int totalUsers = (int) activeInvocations.parallelStream().map(Invocation::getOwner).distinct().count();
        int totalFunctions = (int) activeInvocations.parallelStream().map(Invocation::getFunction).distinct().count();

        int cachedUsers = totalUsers - runningUsers;
        int cachedFunctions = totalFunctions - runningFunctions;
        int cachedInvocationsFootprint = activeInvocations.parallelStream().filter(i -> i.getEndTimestamp() < currentTimestamp).mapToInt(Invocation::getMemory).sum();

        statistics.add(new OutputEntry(
                currentTimestamp,
                invocationsProcessed - lastInvocationsProcessed,
                coldStarts,
                runningUsers,
                runningFunctions,
                runningInvocations.size(),
                runningInvocationsFootprint,
                cachedUsers,
                cachedFunctions,
                cachedInvocationsFootprint));
    }

    public static List<OutputEntry> simulateInvocations(List<Invocation> invocations, int keepalive, int interval) throws Exception {
        TreeSet<Invocation> activeInvocations = new TreeSet<Invocation>(Invocation.comparator());
        List<OutputEntry> statistics = new LinkedList<>();
        int invocationsProcessed = 0;
        int currentTimestamp = 0;
        int previousTimestamp = 0;
        int lastInvocationsProcessed = 0;
        int coldStarts = 0;

        System.err.println("Simulating trace with " + invocations.size() + " invocations and keepalive of " + keepalive);
        for (Invocation currentInvocation : invocations) {
            currentTimestamp = currentInvocation.getTimestamp();

            // Remove invocations that have past their keep alive time.
            evictTimedOutInvocations(activeInvocations, currentTimestamp, keepalive);

            // We try to find an inactive invocation that can be replaced with the new one.
            Invocation warm = findWarmInvocation(activeInvocations, currentTimestamp, currentInvocation.getFunction());
            if (warm == null) {
                coldStarts++;
            } else {
                activeInvocations.remove(warm);
            }

            // Add invocation to array of active invocations.
            activeInvocations.add(currentInvocation);
            invocationsProcessed++;

            if (currentTimestamp - previousTimestamp > interval) {
                // Calculate and update statistics.
                updateStatistics(activeInvocations, statistics, currentTimestamp, previousTimestamp, lastInvocationsProcessed, coldStarts, invocationsProcessed);

                // Reset values until the next round.
                previousTimestamp = currentTimestamp;
                lastInvocationsProcessed = invocationsProcessed;
                coldStarts = 0;
            }

            // Progress update...
            if (invocationsProcessed  % Math.max(invocations.size() / 100, 1) == 0) {
                System.err.println(String.format("Processed %s (%.2f %%)", invocationsProcessed, ((float) invocationsProcessed / (float)invocations.size() * 100)));
            }
        }

        // Final update to statistics.
        updateStatistics(activeInvocations, statistics, currentTimestamp, previousTimestamp, lastInvocationsProcessed, coldStarts, invocationsProcessed);

        return statistics;
    }
}
