#!/bin/bash

# Use this script as following:
# bash run.sh dXX <first-min> <last-min> <max-memory>
#
# dXX is the identifier of the day of observations
# first-min is the first minute to consider
# last-min is the last minute to consider
# max-memory is the desired anticipated max memory consumption in MB

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
GREEN='\033[0;32m'
NC='\033[0m' # No Color

cd "$DIR" || {
  echo "Redirection failed!"
  exit 1
}

DAY_ID=$1
FIRST_MIN=$2
LAST_MIN=$3
MAX_MEMORY=$4
MAX_USERS=$5
MAX_CINV=$6

echo -e "${GREEN}Processing the Azure dataset...${NC}"
$JAVA_HOME/bin/java -cp build/classes/java/main org.graalvm.argo.dataset.DatasetProcessor $DAY_ID $FIRST_MIN $LAST_MIN $MAX_MEMORY $MAX_USERS $MAX_CINV
echo -e "${GREEN}Processing the Azure dataset...done${NC}"
echo -e "${GREEN}Check the ./output directory for the results.${NC}"
