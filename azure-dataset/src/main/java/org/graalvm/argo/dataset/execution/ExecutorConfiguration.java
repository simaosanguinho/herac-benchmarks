package org.graalvm.argo.dataset.execution;

import org.graalvm.argo.dataset.multilang.FunctionLanguage;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

public class ExecutorConfiguration {

    final String functionRuntime;
    public final String invocationCollocation;
    public final String functionIsolation;
    final String gvSandbox;
    /**
     * If true, then print timestamps instead of issuing requests.
     */
    private final boolean debug;
    private final String lambdaManagerAddress;

    private final Map<FunctionLanguage, FunctionConfiguration[]> functionConfigs;

    ExecutorConfiguration(String functionRuntime, String invocationCollocation, String functionIsolation, String gvSandbox, boolean debug, String lambdaManagerAddress) {
        this.functionRuntime = functionRuntime;
        this.invocationCollocation = invocationCollocation;
        this.functionIsolation = functionIsolation;
        this.gvSandbox = gvSandbox;
        this.debug = debug;
        this.lambdaManagerAddress = lambdaManagerAddress;
        this.functionConfigs = new HashMap<>();
        initFunctionConfigs();
    }

    private void initFunctionConfigs() {
        FunctionConfiguration[] javaConfigs;
        FunctionConfiguration[] javaScriptConfigs;
        FunctionConfiguration[] pythonConfigs;
        if (Environment.GRAALVISOR_RUNTIME.equals(this.functionRuntime)) {
            // Add function configs for Graalvisor.
            javaConfigs = new FunctionConfiguration[] {
                    new FunctionConfiguration(Environment.GV_JV_FILEHASHING_CODE, Environment.GV_JV_FILEHASHING_ENTRYPOINT, Environment.JV_FILEHASHING_PARAMETERS, Environment.JV_FILEHASHING_MEMORY),
                    new FunctionConfiguration(Environment.GV_JV_HTTPREQUEST_CODE, Environment.GV_JV_HTTPREQUEST_ENTRYPOINT, Environment.JV_HTTPREQUEST_PARAMETERS, Environment.JV_HTTPREQUEST_MEMORY)
            };
            javaScriptConfigs = new FunctionConfiguration[] {
                    new FunctionConfiguration(Environment.GV_JS_DYNAMICHTML_CODE, Environment.GV_JS_DYNAMICHTML_ENTRYPOINT, Environment.JS_DYNAMICHTML_PARAMETERS, Environment.JS_DYNAMICHTML_MEMORY),
                    new FunctionConfiguration(Environment.GV_JS_UPLOADER_CODE, Environment.GV_JS_UPLOADER_ENTRYPOINT, Environment.JS_UPLOADER_PARAMETERS, Environment.JS_UPLOADER_MEMORY)
            };
            pythonConfigs = new FunctionConfiguration[] {
                    new FunctionConfiguration(Environment.GV_PY_UPLOADER_CODE, Environment.GV_PY_UPLOADER_ENTRYPOINT, Environment.PY_UPLOADER_PARAMETERS, Environment.PY_UPLOADER_MEMORY),
                    new FunctionConfiguration(Environment.GV_PY_COMPRESSION_CODE, Environment.GV_PY_COMPRESSION_ENTRYPOINT, Environment.PY_COMPRESSION_PARAMETERS, Environment.PY_COMPRESSION_MEMORY)
            };
        } else {
            // Add function configs for OpenWhisk.
            javaConfigs = new FunctionConfiguration[] {
                    new FunctionConfiguration(Environment.OW_JV_FILEHASHING_CODE, Environment.OW_JV_FILEHASHING_ENTRYPOINT, Environment.JV_FILEHASHING_PARAMETERS, Environment.JV_FILEHASHING_MEMORY),
                    new FunctionConfiguration(Environment.OW_JV_HTTPREQUEST_CODE, Environment.OW_JV_HTTPREQUEST_ENTRYPOINT, Environment.JV_HTTPREQUEST_PARAMETERS, Environment.JV_HTTPREQUEST_MEMORY)
            };
            javaScriptConfigs = new FunctionConfiguration[] {
                    new FunctionConfiguration(Environment.OW_JS_DYNAMICHTML_CODE, Environment.OW_JS_DYNAMICHTML_ENTRYPOINT, Environment.JS_DYNAMICHTML_PARAMETERS, Environment.JS_DYNAMICHTML_MEMORY),
                    new FunctionConfiguration(Environment.OW_JS_UPLOADER_CODE, Environment.OW_JS_UPLOADER_ENTRYPOINT, Environment.JS_UPLOADER_PARAMETERS, Environment.JS_UPLOADER_MEMORY)
            };
            pythonConfigs = new FunctionConfiguration[] {
                    new FunctionConfiguration(Environment.OW_PY_UPLOADER_CODE, Environment.OW_PY_UPLOADER_ENTRYPOINT, Environment.PY_UPLOADER_PARAMETERS, Environment.PY_UPLOADER_MEMORY),
                    new FunctionConfiguration(Environment.OW_PY_COMPRESSION_CODE, Environment.OW_PY_COMPRESSION_ENTRYPOINT, Environment.PY_COMPRESSION_PARAMETERS, Environment.PY_COMPRESSION_MEMORY)
            };
        }
        functionConfigs.put(FunctionLanguage.JAVA, javaConfigs);
        functionConfigs.put(FunctionLanguage.JAVASCRIPT, javaScriptConfigs);
        functionConfigs.put(FunctionLanguage.PYTHON, pythonConfigs);
    }

    public boolean isDebugMode() {
        return debug;
    }

    public String getLambdaManagerAddress() {
        return lambdaManagerAddress;
    }

    public FunctionConfiguration getFunctionConfiguration(FunctionLanguage language, int functionId) {
        return functionConfigs.get(language)[functionId];
    }

    public class FunctionConfiguration {
        // Contains path to the code instead of the code itself due to LocalFunctionStorage in Lambda Manager.
        final byte[] code;
        final String entryPoint;
        final byte[] payload;
        public final int memory;

        private FunctionConfiguration(String code, String entryPoint, String payload, int memory) {
            this.code = code.getBytes(StandardCharsets.UTF_8);
            this.entryPoint = entryPoint;
            this.payload = payload.getBytes(StandardCharsets.UTF_8);
            this.memory = memory;
        }
    }
}
