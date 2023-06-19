#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
GREEN='\033[0;32m'
NC='\033[0m' # No Color

cd "$DIR" || {
  echo "Redirection failed!"
  exit 1
}

JAR=build/libs/azure-dataset-1.0-all.jar
MAIN=org.graalvm.argo.dataset.InvocationTraceSimulator

echo -e "${GREEN}Simulating invocation trace from the Azure dataset...${NC}"
$JAVA_HOME/bin/java -Xmx16g -cp $JAR $MAIN $@
echo -e "${GREEN}Simulating invocation trace from the Azure dataset...done${NC}"
