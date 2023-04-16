#!/bin/bash

# Use this script as following:
# bash get-plot-data.sh <invocations-file> <output-file> [<keep-alive-in-ms>]

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
GREEN='\033[0;32m'
NC='\033[0m' # No Color

cd "$DIR" || {
  echo "Redirection failed!"
  exit 1
}

INVOCATIONS_FILE=$1
OUTPUT_FILE=$2
KEEP_ALIVE=$3

echo -e "${GREEN}Obtaining plot data...${NC}"
$JAVA_HOME/bin/java -cp build/classes/java/main org.graalvm.argo.dataset.PlotDataGenerator $INVOCATIONS_FILE $OUTPUT_FILE $KEEP_ALIVE
echo -e "${GREEN}Obtaining plot data...done${NC}"
echo -e "${GREEN}Check the ./output directory for the results.${NC}"
