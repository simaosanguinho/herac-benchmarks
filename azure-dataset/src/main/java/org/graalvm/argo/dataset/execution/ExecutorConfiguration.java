package org.graalvm.argo.dataset.execution;

import org.graalvm.argo.dataset.multilang.FunctionLanguage;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

public class ExecutorConfiguration {

    final String functionMemory;
    final String functionRuntime;
    final String invocationCollocation;
    final String functionIsolation;
    final String gvSandbox;
    /**
     * If true, then print timestamps instead of issuing requests.
     */
    private final boolean debug;
    private final String lambdaManagerAddress;

    private final Map<FunctionLanguage, FunctionConfiguration> functionConfigs;

    ExecutorConfiguration(String functionMemory, String functionRuntime, String invocationCollocation, String functionIsolation, String gvSandbox, boolean debug, String lambdaManagerAddress) {
        this.functionMemory = functionMemory;
        this.functionRuntime = functionRuntime;
        this.invocationCollocation = invocationCollocation;
        this.functionIsolation = functionIsolation;
        this.gvSandbox = gvSandbox;
        this.debug = debug;
        this.lambdaManagerAddress = lambdaManagerAddress;
        this.functionConfigs = new HashMap<>(3);
        initFunctionConfigs();
    }

    private void initFunctionConfigs() {
        FunctionConfiguration javaConfig;
        FunctionConfiguration javaScriptConfig;
        FunctionConfiguration pythonConfig;
        if (Environment.GRAALVISOR_RUNTIME.equals(this.functionRuntime)) {
            // Add function configs for Graalvisor.
            javaConfig = new FunctionConfiguration(Environment.GV_JV_FILEHASHING_CODE, Environment.GV_JV_FILEHASHING_ENTRYPOINT, Environment.JV_FILEHASHING_PARAMETERS);
            javaScriptConfig = new FunctionConfiguration(Environment.GV_JS_DYNAMICHTML_CODE, Environment.GV_JS_DYNAMICHTML_ENTRYPOINT, Environment.JS_DYNAMICHTML_PARAMETERS);
            pythonConfig = new FunctionConfiguration(Environment.GV_PY_COMPRESSION_CODE, Environment.GV_PY_COMPRESSION_ENTRYPOINT, Environment.PY_COMPRESSION_PARAMETERS);
        } else {
            // Add function configs for OpenWhisk.
            javaConfig = new FunctionConfiguration(Environment.OW_JV_FILEHASHING_CODE, Environment.OW_JV_FILEHASHING_ENTRYPOINT, Environment.JV_FILEHASHING_PARAMETERS);
            javaScriptConfig = new FunctionConfiguration(Environment.OW_JS_DYNAMICHTML_CODE, Environment.OW_JS_DYNAMICHTML_ENTRYPOINT, Environment.JS_DYNAMICHTML_PARAMETERS);
            pythonConfig = new FunctionConfiguration(Environment.OW_PY_COMPRESSION_CODE, Environment.OW_PY_COMPRESSION_ENTRYPOINT, Environment.PY_COMPRESSION_PARAMETERS);
        }
        functionConfigs.put(FunctionLanguage.JAVA, javaConfig);
        functionConfigs.put(FunctionLanguage.JAVASCRIPT, javaScriptConfig);
        functionConfigs.put(FunctionLanguage.PYTHON, pythonConfig);
    }

    public boolean isDebugMode() {
        return debug;
    }

    public String getLambdaManagerAddress() {
        return lambdaManagerAddress;
    }

    public FunctionConfiguration getFunctionConfiguration(FunctionLanguage language) {
        return functionConfigs.get(language);
    }

    class FunctionConfiguration {
        // Contains path to the code instead of the code itself due to LocalFunctionStorage in Lambda Manager.
        final byte[] code;
        final String entryPoint;
        final byte[] payload;

        private FunctionConfiguration(String code, String entryPoint, String payload) {
            this.code = code.getBytes(StandardCharsets.UTF_8);
            this.entryPoint = entryPoint;
            this.payload = payload.getBytes(StandardCharsets.UTF_8);
        }
    }
}
