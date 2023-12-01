package org.graalvm.argo.dataset.execution;

public class Environment {

    public final static int WORKER_COUNT = 100;
    public final static int MAX_MEMORY_PER_WORKER_MB = 98304;
    public final static int REAL_WORKER_INDEX = 95;
    public final static String REAL_WORKER_TRACE_OUTPUT = "/tmp/lse_trace.csv";

    public static final int VM_MEMORY = 512;

    private static final String ARGO_HOME_PATH = System.getenv("ARGO_HOME");
    private static final String HOST_ADDRESS = "http://172.18.0.1:8000";

    public static final String GRAALVISOR_RUNTIME = "graalvisor";

    // Graalvisor benchmarks.
    public static final String GV_PY_HELLOWORLD_CODE = ARGO_HOME_PATH + "/../benchmarks/src/python/gv-hello-world/build/libhelloworld.so";
    public static final String GV_PY_HELLOWORLD_ENTRYPOINT = "com.helloworld.HelloWorld";
    public static final String GV_JS_DYNAMICHTML_CODE = ARGO_HOME_PATH + "/../benchmarks/src/javascript/gv-dynamic-html/build/libdynamichtml.so";
    public static final String GV_JS_DYNAMICHTML_ENTRYPOINT = "com.dynamichtml.DynamicHTML";
    public static final String GV_JV_FILEHASHING_CODE = ARGO_HOME_PATH + "/../benchmarks/src/java/gv-file-hashing/build/libfilehashing.so";
    public static final String GV_JV_FILEHASHING_ENTRYPOINT = "com.filehashing.FileHashing";

    // OpenWhisk benchmarks.
    public static final String OW_PY_HELLOWORLD_CODE = ARGO_HOME_PATH + "/../benchmarks/src/python/cr-hello-world/init.json";
    public static final String OW_PY_HELLOWORLD_ENTRYPOINT = "main";
    public static final String OW_JS_DYNAMICHTML_CODE = ARGO_HOME_PATH + "/../benchmarks/src/javascript/cr-dynamic-html/init.json";
    public static final String OW_JS_DYNAMICHTML_ENTRYPOINT = "main";
    public static final String OW_JV_FILEHASHING_CODE = ARGO_HOME_PATH + "/../benchmarks/src/java/cr-file-hashing/init.json";
    public static final String OW_JV_FILEHASHING_ENTRYPOINT = "Main";

    // Invocation parameters for benchmarks.
    public static final String PY_HELLOWORLD_PARAMETERS = "{ }";
    public static final String JS_DYNAMICHTML_PARAMETERS = "{\"url\":\"" + HOST_ADDRESS + "/template.html\",\"username\":\"rbruno\",\"nsize\":\"10\"}";
    public static final String JV_FILEHASHING_PARAMETERS = "{\"url\":\"" + HOST_ADDRESS + "/snap.png\"}";

    // Function sizes in MB (only matters for collocatable Graalvisor).
    public static final int PY_HELLOWORLD_MEMORY = 256;
    public static final int JS_DYNAMICHTML_MEMORY = 128;
    public static final int JV_FILEHASHING_MEMORY = 2;

    // Legacy GenericApp configuration.
    public static final String GV_JV_GENERICAPP_CODE = ARGO_HOME_PATH + "/../benchmarks/src/java/gv-genericapp/build/libgenericapp.so";
    public static final String GV_JV_GENERICAPP_ENTRYPOINT = "com.genericapp.GenericApp";
    public static final String GV_JV_GENERICAPP_PARAMETERS_TEMPLATE = "{\"memory\":\"%d\",\"duration\":\"%d\"}";
}
