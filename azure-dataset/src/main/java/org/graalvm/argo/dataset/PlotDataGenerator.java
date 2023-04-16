package org.graalvm.argo.dataset;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.LinkedList;
import java.util.List;

// TODO - we need a better name :-)
public class PlotDataGenerator {
    public static void main(String[] args) {
        String invocationsFile = args[0];
        String outputFile = args[1];
        int keepAlive = 0;
        if (args.length > 2) {
            keepAlive = Integer.valueOf(args[2]);
        }
        process(invocationsFile, outputFile, keepAlive);
    }

    private static void process(String invocationsFile, String outputFile, int keepAlive) {
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
        // TODO - Why do we need a different class? Isn't that class where we simulate the users and functions? Why is an util then?
        PlottingUtils.printTraceSimulation(invocations, outputFile, keepAlive);
    }
}
