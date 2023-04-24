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
 * 1) The day of observations, that will be used as dataset ID (the dXX part);
 * 2) The first minute to consider;
 * 3) The last minute to consider;
 * 4) Desired max memory consumption during the experiment (in MB);
 * 5) The maximum number of users that should be included in the resulting invocation set;
 * 6) The maximum number of concurrent invocations;
 * This program expects raw dataset files to be placed in the "input" directory,
 * and will put results in the "output" directory.
 * Example usage:
 * $ java DatasetProcessor d01 1 2 1000 1000 1000
 * This way you will get all invocations for the first two minutes of
 * the day 1 from the initial dataset, so that the forecasted memory
 * consumption will not exceed 1 GB (1000 MB). We will also firter invocations
 * from the most 1000 popular users and limit concurrent invocations to 1000.
 */
public class DatasetProcessor {

    public static final String DELIMITER = ",";
    private static final int MINUTES_COLUMN_OFFSET = 3;
    private static final List<Invocation> invocations = new LinkedList<>();
    private static final Map<String, Owner> owners = new HashMap<>(2048);
    private static int skipped = 0;

    public static void main(String[] args) throws Exception {
        String datasetId = args[0];
        int firstMinute = Integer.parseInt(args[1]);
        int lastMinute = Integer.parseInt(args[2]);
        int maxMemory = args.length > 3 ? Integer.parseInt(args[3]) : 0;
        int maxUsers = args.length > 4 ? Integer.parseInt(args[4]) : 0;
        int maxConcInv = args.length > 5 ? Integer.parseInt(args[5]) : 0;

        FunctionInfoStorage.fillFunctionData(datasetId);
        processDay(datasetId, firstMinute, lastMinute);

        if (maxConcInv != 0) {
            System.out.println("Number of invocations *before* filter by concurrent invocations: " + invocations.size());
            downscaleByConcurrentInvocations(maxConcInv);
            System.out.println("Number of invocations *after* filter by concurrent invocations: " + invocations.size());
        }

        if (maxUsers != 0) {
            System.out.println("Number of invocations *before* filter by number of users: " + invocations.size());
            downscaleByUser(maxUsers);
            System.out.println("Number of invocations *after* filter by number of users: " + invocations.size());
        }

        if (maxMemory != 0) {
            System.out.println("Number of invocations *before* filter by memory: " + invocations.size());
            downscaleByMemory(maxMemory);
            System.out.println("Number of invocations *after* filter by memory: " + invocations.size());
        }

        /* Now we have ordered and downscaled list of all invocations that we can write as a result */
        List<String> acceptedInvocations = new LinkedList<>();
        acceptedInvocations.add("HashOwner,HashFunction,AverageAllocatedMb,AverageDuration,Timestamp");
        acceptedInvocations.addAll(invocations.stream().map(Invocation::toString).collect(Collectors.toList()));

        Path resultFile = Paths.get("output", String.format("result_%s.csv", datasetId));
        Files.write(resultFile, acceptedInvocations, StandardCharsets.UTF_8);
    }

    private static void processFunction(String line, int firstMinute, int lastMinute) {
        String[] splitRow = line.split(DELIMITER);
        String owner = splitRow[0];
        String app = splitRow[1];
        String function = splitRow[2];

        /* If there is no record about this function about avg duration or memory, then skip */
        if (!FunctionInfoStorage.DURATIONS.containsKey(function) || !FunctionInfoStorage.MEMORIES.containsKey(app)) {
            ++skipped;
            return;
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

    /*
     * Read data from the CSV file, generate timestamps for the desired time frame.
     * File expected syntax: HashOwner, HashApp, HashFunction, Trigger, 1, 2, 3...
     */
    private static void processDay(String datasetId, int firstMinute, int lastMinute) {
        try {
            File file = new File("input/invocations_per_function_md.anon." + datasetId + ".csv");
            BufferedReader br = new BufferedReader(new FileReader(file));
            String line;
            br.readLine(); // To skip the header

            while ((line = br.readLine()) != null) {
                processFunction(line, firstMinute, lastMinute);
            }
            System.out.println("Skipped " + skipped + " functions due to lack of information.");
            br.close();
        } catch(IOException ioe) {
            ioe.printStackTrace();
        }

        /* At this point, we have the unordered list of all invocations */
        Collections.sort(invocations, Comparator.comparingInt(Invocation::getTimestamp));
        System.out.println("Finished sorting.");
    }

    /* Remove invocations that go over the maximum number of concurrent invocations. */
    private static void downscaleByConcurrentInvocations(int maxConcInv) {
        List<Invocation> activeInvocations = new LinkedList<>();
        ListIterator<Invocation> iter = invocations.listIterator();
        while (iter.hasNext()) {
            Invocation currentInvocation = iter.next();
            int currentInvocationTimestamp = currentInvocation.getTimestamp();

            activeInvocations.removeIf(f -> currentInvocationTimestamp >= f.getEndTimestamp());
            long currentInvokes = activeInvocations.stream().count();

            if (currentInvokes + 1 <= maxConcInv) {
                activeInvocations.add(currentInvocation);
            } else {
                iter.remove();
            }
        }
    }

    /* Remove invocations that are not from the N more popular users. */
    private static void downscaleByUser(int maxUsers) {
        Set<String> selectedOwners = owners.values().stream()
                .sorted(Comparator.comparingInt(Owner::getFunctions).reversed())
                .limit(maxUsers).map(Owner::getOwnerHash).collect(Collectors.toSet());
        invocations.removeIf(i -> !selectedOwners.contains(i.getOwner()));
    }

    /* Remove invocations that go over the maximum memory. */
    private static void downscaleByMemory(int maxMemory) {
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
}
