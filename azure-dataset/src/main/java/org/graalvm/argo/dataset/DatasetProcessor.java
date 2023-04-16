package org.graalvm.argo.dataset;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.ListIterator;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

/**
 * This is the entry point for the Azure dataset processing
 * pipeline. Provide as input:
 * 1) The day of observations, that will be used as dataset ID (the dXX part)
 * 2) The first minute to consider
 * 3) The last minute to consider
 * 4) Desired max memory consumption during the experiment (in MB)
 * This program expects raw dataset files to be placed in the "input" directory,
 * and will put results in the "output" directory.
 * Example usage:
 * $ java DatasetProcessor d01 1 2 1000
 * This way you will get all invocations for the first two minutes of
 * the day 1 from the initial dataset, so that the forecasted memory
 * consumption will not exceed 1 GB (1000 MB)
 */
// TODO - this explanation is good but is missing an explanation of what it produces.
// Is this the class that produces invocations of each function with timestamps?
public class DatasetProcessor {

    public static final String DELIMITER = ",";
    private static final int MINUTES_COLUMN_OFFSET = 3;
    private static final int MOST_ACTIVE_USERS = 1000;

    public static void main(String[] args) {
        String datasetId = args[0];
        int firstMinute = Integer.parseInt(args[1]);
        int lastMinute = Integer.parseInt(args[2]);
        int maxMemory = Integer.parseInt(args[3]);
        FunctionInfoStorage.fillFunctionData(datasetId);
        process(datasetId, firstMinute, lastMinute, maxMemory);
    }

    /*
    HashOwner, HashApp, HashFunction, Trigger, 1, 2, 3...
     */
    private static void process(String datasetId, int firstMinute, int lastMinute, int maxMemory) {
        List<Invocation> invocations = new LinkedList<>();
        Map<String, Owner> owners = new HashMap<>(2048);

        /* Read data from the CSV file, generate timestamps for the desired time frame */
        try {
            File file = new File("input/invocations_per_function_md.anon." + datasetId + ".csv");
            BufferedReader br = new BufferedReader(new FileReader(file));
            String line;
            String[] splitRow;
            br.readLine(); // To skip the header
            int skipped = 0;
            while ((line = br.readLine()) != null) {
                splitRow = line.split(DELIMITER);
                String owner = splitRow[0];
                String app = splitRow[1];
                String function = splitRow[2];
                /* If there is no record about this function about avg duration or memory, then skip */
                if (!FunctionInfoStorage.DURATIONS.containsKey(function) || !FunctionInfoStorage.MEMORIES.containsKey(app)) {
                    ++skipped;
                    continue;
                }

                int memory = FunctionInfoStorage.MEMORIES.get(app);
                int duration = FunctionInfoStorage.DURATIONS.get(function);

                int currentMinute = firstMinute;
                int invocationCount = 0;
                while (currentMinute <= lastMinute) {
                    int invocationsForMinute = Integer.parseInt(splitRow[currentMinute + MINUTES_COLUMN_OFFSET]);
                    invocationCount += invocationsForMinute;
                    int minBeginningMs = (currentMinute - 1) * 60000;
                    int minEndMs = minBeginningMs + 60000;
                    for (int i = 0; i < invocationsForMinute; ++i) {
                        int timestamp = ThreadLocalRandom.current().nextInt(minBeginningMs, minEndMs);
                        invocations.add(new Invocation(owner, function, memory, duration, timestamp));
                    }
                    ++currentMinute;
                }
                if (invocationCount > 0) {
                    if (!owners.containsKey(owner)) {
                        owners.put(owner, new Owner(owner));
                    }
                    Owner currentOwner = owners.get(owner);
                    currentOwner.addFunction(function);
                    currentOwner.addInvocations(invocationCount);
                }
            }
            System.out.println("Skipped " + skipped + " functions due to lack of information.");
            br.close();
        } catch(IOException ioe) {
            ioe.printStackTrace();
        }
        System.out.println("Number of owners in total: " + owners.size());

        /* At this point, we have the unordered list of all invocations */
        Collections.sort(invocations, Comparator.comparingInt(Invocation::getTimestamp));
        System.out.println("Finished sorting.");

        /* If needed, call printTraceSimulation on invocations here to get plot data for unfiltered trace */

        /* get top X users based on number of functions */
        Set<String> selectedOwners = owners.values().stream().sorted(Comparator.comparingInt(Owner::getFunctions).reversed())
                .limit(MOST_ACTIVE_USERS).map(Owner::getOwnerHash).collect(Collectors.toSet());
        System.out.println("Number of invocations before remove: " + invocations.size());
        invocations.removeIf(i -> !selectedOwners.contains(i.getOwner()));
        System.out.println("Number of invocations after remove: " + invocations.size());

        downscaleByMemory(invocations, maxMemory);

        /* Now we have ordered and downscaled list of all invocations that we can write as a result */
        List<String> acceptedInvocations = new LinkedList<>();
        acceptedInvocations.add("HashOwner,HashFunction,AverageAllocatedMb,AverageDuration,Timestamp");
        acceptedInvocations.addAll(invocations.stream().map(Invocation::toString).collect(Collectors.toList()));

        Path resultFile = Paths.get("output", String.format("result_%s.csv", datasetId));
        writeToFile(acceptedInvocations, resultFile);
    }

    private static void downscaleByMemory(List<Invocation> invocations, int maxMemory) {
        List<Invocation> activeInvocations = new LinkedList<>();
        ListIterator<Invocation> iter = invocations.listIterator();
        while (iter.hasNext()) {
            Invocation currentInvocation = iter.next();
            int currentInvocationTimestamp = currentInvocation.getTimestamp();

            activeInvocations.removeIf(f -> currentInvocationTimestamp >= f.getEndTimestamp());
            int currentConsumption = activeInvocations.stream().mapToInt(Invocation::getMemory).sum();

            if (currentConsumption + currentInvocation.getMemory() <= maxMemory) {
                activeInvocations.add(currentInvocation);
            } else {
                iter.remove();
            }
        }
    }

    public static void writeToFile(List<String> data, Path file) {
        try {
            Files.write(file, data, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
