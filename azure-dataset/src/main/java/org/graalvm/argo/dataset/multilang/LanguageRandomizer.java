package org.graalvm.argo.dataset.multilang;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.graalvm.argo.dataset.Invocation;
import org.graalvm.argo.dataset.InvocationTraceGenerator;

import java.io.*;
import java.util.*;
import java.util.stream.Collectors;

public class LanguageRandomizer {

    // Source: https://newrelic.com/resources/report/serverless-benchmark-report-aws-lambda-2020
    private static final int JAVASCRIPT_PERC = 48; // 54
    private static final int PYTHON_PERC = 24;     // 38
    private static final int JAVA_PERC = 28;       // 8

    public static void main(String[] args) {
        Options options = prepareOptions();
        try {
            CommandLine cmd = new DefaultParser().parse(options, args);
            String inputFilePath = cmd.getOptionValue("input");
            String outputFilePath = cmd.getOptionValue("trace", inputFilePath);
            processLanguages(inputFilePath, outputFilePath);
        } catch (ParseException e) {
            System.out.println(e.getMessage());
            new HelpFormatter().printHelp("utility-name", options);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void processLanguages(String inputFilePath, String outputFilePath) {
        List<Invocation> invocations = getInvocations(inputFilePath);
        Map<String, FunctionLanguage> languagesFunction = getLanguages(invocations);
        writeInvocationsToFile(invocations, languagesFunction, outputFilePath);
    }

    private static void writeInvocationsToFile(List<Invocation> invocations, Map<String, FunctionLanguage> languagesFunction, String outputFilePath) {
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(outputFilePath, false))) {
            writer.write("HashOwner,HashFunction,AverageAllocatedMb,AverageDuration,Timestamp,Language");
            writer.newLine();
            for (Invocation invocation : invocations) {
                writer.write(String.format("%s,%s", invocation.toString(), languagesFunction.get(invocation.getFunction())));
                writer.newLine();
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private static Map<String, FunctionLanguage> getLanguages(List<Invocation> invocations) {
        int invocationsNumber = invocations.size();
        Map<String, FunctionLanguage> result = new HashMap<>();

        Map<String, Long> invocationsFunction = invocations.stream()
                .collect(Collectors.groupingBy(Invocation::getFunction, Collectors.counting()));
        List<Map.Entry<String, Long>> functionsList = new ArrayList<>(invocationsFunction.entrySet());
        Collections.shuffle(functionsList);

        int currentInvocationsNumber = 0;
        int jsThreshold = (int) (invocationsNumber * ((double) JAVASCRIPT_PERC / 100));
        int pyThreshold = (int) (invocationsNumber * ((double) PYTHON_PERC / 100)) + jsThreshold;
        int jvThreshold = (int) (invocationsNumber * ((double) JAVA_PERC / 100)) + pyThreshold;
        for (Map.Entry<String, Long> functionEntry : functionsList) {
            currentInvocationsNumber += functionEntry.getValue();
            if (currentInvocationsNumber <= jsThreshold) {
                result.put(functionEntry.getKey(), FunctionLanguage.JAVASCRIPT);
            } else if (currentInvocationsNumber <= pyThreshold) {
                result.put(functionEntry.getKey(), FunctionLanguage.PYTHON);
            } else {
                result.put(functionEntry.getKey(), FunctionLanguage.JAVA);
            }
        }
        System.out.println("Total invocations: " + invocationsNumber);
        System.out.println("Expected number of JS invocations: " + (int) (invocationsNumber * ((double) JAVASCRIPT_PERC / 100)));
        System.out.println("Expected number of PY invocations: " + (int) (invocationsNumber * ((double) PYTHON_PERC / 100)));
        System.out.println("Expected number of JV invocations: " + (int) (invocationsNumber * ((double) JAVA_PERC / 100)));
        return result;
    }

    private static List<Invocation> getInvocations(String inputFilePath) {
        List<Invocation> invocations = new LinkedList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(inputFilePath))) {
            String line;
            String[] splitRow;
            br.readLine(); // To skip the header
            while ((line = br.readLine()) != null) {
                splitRow = line.split(InvocationTraceGenerator.DELIMITER);
                String owner = splitRow[0];
                String function = splitRow[1];
                int allocatedMemoryMb = Integer.parseInt(splitRow[2]);
                int duration = Integer.parseInt(splitRow[3]);
                int timestamp = Integer.parseInt(splitRow[4]);
                invocations.add(new Invocation(owner, function, allocatedMemoryMb, duration, timestamp));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return invocations;
    }

    private static Options prepareOptions() {
        Options options = new Options();
        Option input = new Option("i", "input", true, "Input invocation trace file path.");
        input.setRequired(true);
        options.addOption(input);
        Option output = new Option("t", "trace", true, "Output invocation trace file path.");
        output.setRequired(true);
        options.addOption(output);
        return options;
    }
}
