function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

AZURE_EXECUTOR_JAR=$(DIR)/build/libs/azure-dataset-1.0-all.jar
AZURE_EXECUTOR_ENTRYPOINT=org.graalvm.argo.dataset.execution.ExecutorEntryPoint

function_code="$ARGO_HOME/../benchmarks/src/java/gv-genericapp/build/libgenericapp.so"
function_entry_point="com.genericapp.GenericApp"

time $JAVA_HOME/bin/java -cp $AZURE_EXECUTOR_JAR $AZURE_EXECUTOR_ENTRYPOINT \
        --input $1 \
        --functionCode $function_code \
        --functionLanguage java \
        --functionEntryPoint $function_entry_point \
        --functionMemory 16 \
        --functionRuntime "graalvisor" \
        --invocationCollocation "true" \
        --functionIsolation "false" \
        --multiWorker
