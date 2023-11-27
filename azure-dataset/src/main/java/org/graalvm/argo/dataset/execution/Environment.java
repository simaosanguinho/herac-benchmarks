package org.graalvm.argo.dataset.execution;

public class Environment {
    private static final String ARGO_HOME_PATH = System.getenv("ARGO_HOME");
    private static final String HOST_ADDRESS = "http://172.18.0.1:8000";

    public static final String GRAALVISOR_RUNTIME = "graalvisor";

    // Legacy GenericApp configuration.
    public static final String GV_JV_GENERICAPP_CODE = ARGO_HOME_PATH + "/../benchmarks/src/java/gv-genericapp/build/libgenericapp.so";
    public static final String GV_JV_GENERICAPP_ENTRYPOINT = "com.genericapp.GenericApp";
    public static final String GV_JV_GENERICAPP_PARAMETERS_TEMPLATE = "{\"memory\":\"%d\",\"duration\":\"%d\"}";

    // Graalvisor benchmarks.
    public static final String GV_PY_COMPRESSION_CODE = ARGO_HOME_PATH + "/../benchmarks/src/python/gv-compression/build/libcompression.so";
    public static final String GV_PY_COMPRESSION_ENTRYPOINT = "com.compression.Compression";
    public static final String GV_JS_DYNAMICHTML_CODE = ARGO_HOME_PATH + "/../benchmarks/src/javascript/gv-dynamic-html/build/libdynamichtml.so";
    public static final String GV_JS_DYNAMICHTML_ENTRYPOINT = "com.dynamichtml.DynamicHTML";
    public static final String GV_JV_FILEHASHING_CODE = ARGO_HOME_PATH + "/../benchmarks/src/java/gv-file-hashing/build/libfilehashing.so";
    public static final String GV_JV_FILEHASHING_ENTRYPOINT = "com.filehashing.FileHashing";

    // OpenWhisk benchmarks.
    public static final String OW_PY_COMPRESSION_CODE = ARGO_HOME_PATH + "/../benchmarks/src/python/cr-compression/init.json";
    public static final String OW_PY_COMPRESSION_ENTRYPOINT = "main";
    public static final String OW_JS_DYNAMICHTML_CODE = ARGO_HOME_PATH + "/../benchmarks/src/javascript/cr-dynamic-html/init.json";
    public static final String OW_JS_DYNAMICHTML_ENTRYPOINT = "main";
    public static final String OW_JV_FILEHASHING_CODE = ARGO_HOME_PATH + "/../benchmarks/src/java/cr-file-hashing/init.json";
    public static final String OW_JV_FILEHASHING_ENTRYPOINT = "Main";

    // Invocation parameters for benchmarks.
    public static final String PY_COMPRESSION_PARAMETERS = "{\"url\":\"" + HOST_ADDRESS + "/video.mp4\"}";
    public static final String JS_DYNAMICHTML_PARAMETERS = "{\"url\":\"" + HOST_ADDRESS + "/template.html\",\"username\":\"rbruno\",\"nsize\":\"10\"}";
    public static final String JV_FILEHASHING_PARAMETERS = "{\"url\":\"" + HOST_ADDRESS + "/video.mp4\"}";
}
