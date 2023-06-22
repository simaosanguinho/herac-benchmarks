package org.graalvm.argo.dataset;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
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
     * Output file format. For each line, the file contains the following entries:
     * - currentInvocationTimestamp, the timestamp (ms) corresponding to the current moment of the simulation;
     * - runningUsers, number of different users that have functions running at the moment;
     * - runningFunctions, number of different functions that are running at the moment;
     * - cachedUsers, number of different users with active but not running functions;
     * - cachedFunctions, number of different functions that are active but not running;
     * - runningInvocations, number of running invocations;
     * - runningInvocationsFootprint, total memory footprint (MB) of the running invocations;
     * - cachedInvocationsFootprint, total memory footprint (MB) used by cached functions;
     * - coldStarts, number of cold starts since the last simulation round;
     * - invocations, number of processed invocations since the last round.
     */
    private static final String AGGREGATED_INVOCATION_DATA = "%d %d %d %d %d %d %d %d %d %d";
    // The input trace of invocations (generated with the invocation trace generator.
    private static final List<Invocation> INVOCATIONS = new LinkedList<>();

    private static Options prepareOptions() {
        Options options = new Options();
        Option input = new Option("i", "input", true, "Input invocation trace file path.");
        input.setRequired(true);
        options.addOption(input);
        Option output = new Option("o", "output", true, "Output file path.");
        output.setRequired(false);
        options.addOption(output);
        Option keepalive = new Option("k", "keepalive", true, "Function keep alive time in milliseconds.");
        keepalive.setRequired(false);
        options.addOption(keepalive);
        Option cachesize = new Option("c", "cachesize", true, "Size of the functio cache in MBs.");
        cachesize.setRequired(false);
        options.addOption(cachesize);
        return options;
    }

    public static void main(String[] args) throws Exception {
        Options options = prepareOptions();
        try {
            CommandLine cmd = new DefaultParser().parse(options, args);
            String inputFile = cmd.getOptionValue("input");
            String outputFile = cmd.getOptionValue("output", null);
            int keepAlive = Integer.parseInt(cmd.getOptionValue("keepalive", "0"));
            int cachesize = Integer.parseInt(cmd.getOptionValue("cachesize", "0"));
            loadInvocations(inputFile, outputFile, keepAlive);
            simulateInvocations(outputFile, keepAlive, cachesize);
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

    private static void simulateInvocations(String outputfile, int keepAlive, int cachesize) throws Exception {
        TreeSet<Invocation> activeInvocations = new TreeSet<Invocation>(Invocation.comparator());
        List<String> aggregatedInvocationData = new LinkedList<>();
        int lastTimestamp = 0;
        int lastInvocationsProcessed = 0;
        long coldStarts = 0;
        int invocationsProcessed = 0;

        System.out.println("Simulating trace with " + INVOCATIONS.size() + " invocations and keepalive of " + keepAlive);
        for (Invocation currentInvocation : INVOCATIONS) {
            int currentInvocationTimestamp = currentInvocation.getTimestamp();

            // Remove invocations that have past their keep alive time.
            evictTimedOutInvocations(activeInvocations, currentInvocationTimestamp, keepAlive);

            // We try to find an inactive invocation that can be replaced with the new one.
            Invocation warm = findWarmInvocation(activeInvocations, currentInvocationTimestamp, currentInvocation.getFunction());
            if (warm == null) {
                coldStarts++;
            } else {
                activeInvocations.remove(warm);
            }

            // Add invocation to array of active invocations.
            activeInvocations.add(currentInvocation);

            if (currentInvocationTimestamp - lastTimestamp > 1000) {

                // Total footprint of functions are active but not running.
                long cachedInvocationsFootprint = activeInvocations.parallelStream().filter(i -> i.getEndTimestamp() < currentInvocationTimestamp).mapToInt(Invocation::getMemory).sum();
/*
                // Calculate if we are over the cache footprint limit.
                long over = cachedInvocationsFootprint - cachesize;

                // If we are over, iterate over cached invocations and evict until we are under the limit.
                if (over > 0) {
                    List<Invocation> evicted = new ArrayList<>();
                    for (Invocation invocation : activeInvocations) {
                        if (invocation.getEndTimestamp() < currentInvocationTimestamp) {
                            over = over - invocation.getMemory();
                            evicted.add(invocation);
                            if (over <= 0) {
                                break;
                            }
                        }
                    }
                    activeInvocations.removeAll(evicted);
                }
*/
                /* Gather aggregated invocation data for plot at most once per minute.*/
                List<Invocation> runningInvocations = activeInvocations.parallelStream().filter(i -> i.getEndTimestamp() > currentInvocationTimestamp).collect(Collectors.toList());
                long runningUsers = runningInvocations.parallelStream().map(Invocation::getOwner).distinct().count();
                long runningFunctions  = runningInvocations.parallelStream().map(Invocation::getFunction).distinct().count();
                long runningInvocationsFootprint = runningInvocations.parallelStream().mapToInt(Invocation::getMemory).sum();

                long totalUsers = activeInvocations.parallelStream().map(Invocation::getOwner).distinct().count();
                long totalFunctions = activeInvocations.parallelStream().map(Invocation::getFunction).distinct().count();

                long cachedUsers = totalUsers - runningUsers;
                long cachedFunctions = totalFunctions - runningFunctions;

                aggregatedInvocationData.add(String.format(AGGREGATED_INVOCATION_DATA,
                        currentInvocationTimestamp,
                        runningUsers,
                        runningFunctions,
                        cachedUsers,
                        cachedFunctions,
                        runningInvocations.size(),
                        runningInvocationsFootprint,
                        cachedInvocationsFootprint,
                        coldStarts,
                        invocationsProcessed - lastInvocationsProcessed));

                // Reset values until the next round.
                lastTimestamp = currentInvocationTimestamp;
                lastInvocationsProcessed = invocationsProcessed;
                coldStarts = 0;
            }

            ++invocationsProcessed;

            // Progress update...
            if (invocationsProcessed  % Math.max(INVOCATIONS.size() / 100, 1) == 0) {
                System.err.println(String.format("Processed %s (%.2f %%)", invocationsProcessed, ((float) invocationsProcessed / (float)INVOCATIONS.size() * 100)));
            }
        }

        // Write output.
        if (outputfile != null) {
            Files.write(Paths.get(outputfile), aggregatedInvocationData, StandardCharsets.UTF_8);
        } else {
            for (String element : aggregatedInvocationData) {
                System.out.println(element);
            }
        }
    }
}
