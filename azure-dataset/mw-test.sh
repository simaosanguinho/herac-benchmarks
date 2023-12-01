function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

AZURE_EXECUTOR_JAR=$(DIR)/build/libs/azure-dataset-1.0-all.jar
AZURE_EXECUTOR_ENTRYPOINT=org.graalvm.argo.dataset.execution.ExecutorEntryPoint


MODE=$1
DATASET_FILE=$2

if [[ "$MODE" = "gv" ]]; then
    FUNCTION_ISOLATION=false
    INVOCATION_COLLOCATION=true
elif [[ "$MODE" = "gv-sf" ]]; then
    FUNCTION_ISOLATION=true
    INVOCATION_COLLOCATION=true
elif [[ "$MODE" = "gv-si" ]]; then
    FUNCTION_ISOLATION=true
    INVOCATION_COLLOCATION=false
else
    echo "Syntax: <mode> </path/to/dataset/directory>"
	exit 1
fi

time $JAVA_HOME/bin/java -cp $AZURE_EXECUTOR_JAR $AZURE_EXECUTOR_ENTRYPOINT \
        --input $DATASET_FILE \
        --functionRuntime "graalvisor" \
        --invocationCollocation $INVOCATION_COLLOCATION \
        --functionIsolation $FUNCTION_ISOLATION \
        --multiWorker > /tmp/mw_test_execution.log
