package org.graalvm.argo.dataset.execution;

import org.graalvm.argo.dataset.InvocationTraceGenerator;
import org.graalvm.argo.dataset.multilang.FunctionLanguage;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashSet;
import java.util.Set;
import java.util.function.Consumer;

public class InvocationTraceExecutor {

    protected final ExecutorConfiguration config;


    public InvocationTraceExecutor(ExecutorConfiguration config) {
        this.config = config;
    }

    // HashOwner,HashFunction,AverageAllocatedMb,AverageDuration,Timestamp
    public void execute(String invocationsFilePath) {
        uploadFunctions(invocationsFilePath);
        try (BufferedReader br = new BufferedReader(new FileReader(invocationsFilePath))) {
            String line;
            String[] splitRow;
            br.readLine(); // To skip the header
            int currentTimestamp = 0;
            while ((line = br.readLine()) != null) {
                splitRow = line.split(InvocationTraceGenerator.DELIMITER);
                String owner = splitRow[0];
                String function = splitRow[1];
                int timestamp = Integer.parseInt(splitRow[4]);
                FunctionLanguage language = FunctionLanguage.fromString(splitRow[5]);
                int functionId = Integer.parseInt(splitRow[6]);

                waitForInvocation(currentTimestamp, timestamp);
                currentTimestamp = timestamp;

                invokeFunction(owner, function, timestamp, language, functionId, (s) -> {});
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void uploadFunctions(String invocationsFilePath) {
        Set<String> uploadedFunctions = new HashSet<>();
        try (BufferedReader br = new BufferedReader(new FileReader(invocationsFilePath))) {
            String line;
            String[] splitRow;
            br.readLine(); // To skip the header
            while ((line = br.readLine()) != null) {
                splitRow = line.split(InvocationTraceGenerator.DELIMITER);
                String owner = splitRow[0];
                String function = splitRow[1];
                FunctionLanguage language = FunctionLanguage.fromString(splitRow[5]);
                int functionId = Integer.parseInt(splitRow[6]);
                ensureUploaded(uploadedFunctions, owner, function, language, functionId);
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    protected void ensureUploaded(Set<String> uploadedFunctions, String owner, String function, FunctionLanguage language, int functionId) {
        if (!uploadedFunctions.contains(function)) {
            uploadFunction(owner, function, language, functionId);
            uploadedFunctions.add(function);
        }
    }

    protected void waitForInvocation(int currentTimestamp, int invocationTimestamp) {
        int timeToSleep = invocationTimestamp - currentTimestamp;
        if (timeToSleep != 0) {
            try {
                Thread.sleep(timeToSleep);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public void uploadFunction(String owner, String function, FunctionLanguage language, int functionId) {
        ExecutorConfiguration.FunctionConfiguration functionConfig = config.getFunctionConfiguration(language, functionId);
        // Graalvisor Python/JavaScript benchmarks have Java wrappers.
        FunctionLanguage actualLanguage = Environment.GRAALVISOR_RUNTIME.equals(config.functionRuntime) ? FunctionLanguage.JAVA : language;
        String queryParameters = "username=" + owner + "&function_name=" + function +
                "&function_language=" + actualLanguage + "&function_entry_point=" + functionConfig.entryPoint +
                "&function_memory=" + functionConfig.memory + "&function_runtime=" + config.functionRuntime +
                "&function_isolation=" + config.functionIsolation + "&invocation_collocation=" + config.invocationCollocation;
        if (config.gvSandbox != null) {
            queryParameters = queryParameters + "&gv_sandbox=" + config.gvSandbox;
        }
        if (!config.isDebugMode()) {
            NetworkUtils.sendPost(config.getLambdaManagerAddress(), "/upload_function?" + queryParameters, "application/octet-stream", functionConfig.code, false);
        }
    }

    public void invokeFunction(String owner, String function, int timestamp, FunctionLanguage language, int functionId, Consumer<String> asyncConsumer) {
        ExecutorConfiguration.FunctionConfiguration functionConfig = config.getFunctionConfiguration(language, functionId);
        byte[] data = functionConfig.payload;
        if (config.isDebugMode()) {
            System.out.println("Sending request with timestamp: " + timestamp);
        } else {
            NetworkUtils.sendPost(config.getLambdaManagerAddress(), "/" + owner + "/" + function, "application/json; charset=UTF-8", data, true, asyncConsumer);
        }
    }
}
