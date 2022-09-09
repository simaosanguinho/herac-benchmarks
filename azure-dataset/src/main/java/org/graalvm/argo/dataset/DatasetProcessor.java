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
import java.util.LinkedList;
import java.util.List;
import java.util.ListIterator;
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
public class DatasetProcessor {

    private static final String DELIMITER = ",";
    private static final int MEMORY_INDEX = 0;
    private static final int END_INDEX = 1;
    private static final int MINUTES_COLUMN_OFFSET = 3;

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
                while (currentMinute <= lastMinute) {
                    int invocationsForMinute = Integer.parseInt(splitRow[currentMinute + MINUTES_COLUMN_OFFSET]);
                    int minBeginningMs = (currentMinute - 1) * 60000;
                    int minEndMs = minBeginningMs + 60000;
                    for (int i = 0; i < invocationsForMinute; ++i) {
                        int timestamp = ThreadLocalRandom.current().nextInt(minBeginningMs, minEndMs);
                        invocations.add(new Invocation(owner, function, memory, duration, timestamp));
                    }
                    ++currentMinute;
                }
            }
            System.out.println("Skipped " + skipped + " functions due to lack of information.");
            br.close();
        } catch(IOException ioe) {
            ioe.printStackTrace();
        }

        /* At this point, we have the unordered list of all invocations */
        Collections.sort(invocations, (o1, o2) -> o1.getTimestamp() - o2.getTimestamp());
        downscaleByMemory(invocations, maxMemory);
        /* Now we have ordered and downscaled list of all invocations that we can write as a result */
        List<String> acceptedInvocations = new LinkedList<>();
        acceptedInvocations.add("HashOwner,HashFunction,AverageAllocatedMb,AverageDuration,Timestamp");
        acceptedInvocations.addAll(invocations.stream().map(Invocation::toString).collect(Collectors.toList()));

        Path resultFile = Paths.get("output", String.format("result_%s.csv", datasetId));
        try {
            Files.write(resultFile, acceptedInvocations, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private static void downscaleByMemory(List<Invocation> invocations, int maxMemory) {
        List<int[]> activeFunctions = new LinkedList<>();
        ListIterator<Invocation> iter = invocations.listIterator();
        while (iter.hasNext()) {
            Invocation currentInvocation = iter.next();

            int timestamp = currentInvocation.getTimestamp();
            int memory = currentInvocation.getMemory();
            int end = timestamp + currentInvocation.getDuration();

            activeFunctions.removeIf(f -> timestamp >= f[END_INDEX]);
            int currentConsumption = activeFunctions.stream().mapToInt(f -> f[MEMORY_INDEX]).sum();

            if (currentConsumption + memory <= maxMemory) {
                activeFunctions.add(new int[] {memory, end});
            } else {
                iter.remove();
            }
        }
    }

}
