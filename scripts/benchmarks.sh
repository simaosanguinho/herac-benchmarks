#!/bin/bash

# Import global definitions.
source $(DIR)/globals.sh

# Data is available in the host ip.
DATA_IP=$(ip route get 8.8.8.8 | grep -oP  'src \K\S+')
DATA_PORT=8000

JV_HY_BENCHMARKS=""
# (disabled) #JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS hy_java_sleep"
# (disabled) #JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS hy_java_shopcart"
JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS hy_java_hw"
JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS hy_java_filehashing"
JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS hy_java_classify"
JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS hy_java_httprequest"
JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS hy_java_videoprocessing"

JV_CR_BENCHMARKS=""
# (disabled) #JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_sleep"
# (disabled) #JV_CR_BENCHMARKS="$JV_HY_BENCHMARKS cr_java_shopcart"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_hw"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_filehashing"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_classify"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_httprequest"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_videoprocessing"

JV_KN_BENCHMARKS=""
JV_KN_BENCHMARKS="$JV_KN_BENCHMARKS kn_java_hw"
JV_KN_BENCHMARKS="$JV_KN_BENCHMARKS kn_java_filehashing"
JV_KN_BENCHMARKS="$JV_KN_BENCHMARKS kn_java_classify"
JV_KN_BENCHMARKS="$JV_KN_BENCHMARKS kn_java_httprequest"
JV_KN_BENCHMARKS="$JV_KN_BENCHMARKS kn_java_videoprocessing"

PY_HY_BENCHMARKS=""
# (disabled) #PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_sleep"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_hw"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_mst"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_bfs"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_pagerank"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_dna"
#PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_classify" # TODO - not working.
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_dynamichtml"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_compression"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_thumbnail"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_videoprocessing"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS hy_python_uploader"

PY_CR_BENCHMARKS=""
# (disabled) PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_sleep"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_hw"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_mst"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_bfs"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_pagerank"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_dna"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_classify"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_dynamichtml"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_compression"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_thumbnail"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_videoprocessing"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS cr_python_uploader"

PY_KN_BENCHMARKS=""
PY_KN_BENCHMARKS="$PY_KN_BENCHMARKS kn_python_hw"
PY_KN_BENCHMARKS="$PY_KN_BENCHMARKS kn_python_mst"
PY_KN_BENCHMARKS="$PY_KN_BENCHMARKS kn_python_bfs"
PY_KN_BENCHMARKS="$PY_KN_BENCHMARKS kn_python_pagerank"
PY_KN_BENCHMARKS="$PY_KN_BENCHMARKS kn_python_dna"
PY_KN_BENCHMARKS="$PY_KN_BENCHMARKS kn_python_dynamichtml"
PY_KN_BENCHMARKS="$PY_KN_BENCHMARKS kn_python_compression"
PY_KN_BENCHMARKS="$PY_KN_BENCHMARKS kn_python_thumbnail"
PY_KN_BENCHMARKS="$PY_KN_BENCHMARKS kn_python_videoprocessing"
PY_KN_BENCHMARKS="$PY_KN_BENCHMARKS kn_python_uploader"

JS_HY_BENCHMARKS=""
# (disabled) #JS_HY_BENCHMARKS="$JS_HY_BENCHMARKS hy_javascript_sleep"
JS_HY_BENCHMARKS="$JS_HY_BENCHMARKS hy_javascript_hw"
JS_HY_BENCHMARKS="$JS_HY_BENCHMARKS hy_javascript_dynamichtml"
JS_HY_BENCHMARKS="$JS_HY_BENCHMARKS hy_javascript_thumbnail"
JS_HY_BENCHMARKS="$JS_HY_BENCHMARKS hy_javascript_uploader"

JS_CR_BENCHMARKS=""
# (disabled) #JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS cr_javascript_sleep"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS cr_javascript_hw"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS cr_javascript_dynamichtml"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS cr_javascript_thumbnail"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS cr_javascript_uploader"

JS_KN_BENCHMARKS=""
JS_KN_BENCHMARKS="$JS_KN_BENCHMARKS kn_javascript_hw"
JS_KN_BENCHMARKS="$JS_KN_BENCHMARKS kn_javascript_dynamichtml"
JS_KN_BENCHMARKS="$JS_KN_BENCHMARKS kn_javascript_thumbnail"
JS_KN_BENCHMARKS="$JS_KN_BENCHMARKS kn_javascript_uploader"

HY_BENCHMARKS="$JV_HY_BENCHMARKS $PY_HY_BENCHMARKS $JS_HY_BENCHMARKS"
CR_BENCHMARKS="$JV_CR_BENCHMARKS $PY_CR_BENCHMARKS $JS_CR_BENCHMARKS"
KN_BENCHMARKS="$JV_KN_BENCHMARKS $PY_KN_BENCHMARKS $JS_KN_BENCHMARKS"

# These values are recommended values for running each benchmark. These values
# are used when running experiments.
declare -A wmultiplier_table
wmultiplier_table[hy_java_hw]=2000
wmultiplier_table[cr_java_hw]=16000
wmultiplier_table[kn_java_hw]=16000
wmultiplier_table[hy_java_filehashing]=2000
wmultiplier_table[cr_java_filehashing]=4000
wmultiplier_table[kn_java_filehashing]=4000
wmultiplier_table[hy_java_classify]=10
wmultiplier_table[cr_java_classify]=10
wmultiplier_table[kn_java_classify]=10
wmultiplier_table[hy_java_httprequest]=1000
wmultiplier_table[cr_java_httprequest]=8000
wmultiplier_table[kn_java_httprequest]=8000
wmultiplier_table[hy_java_videoprocessing]=10
wmultiplier_table[cr_java_videoprocessing]=10
wmultiplier_table[kn_java_videoprocessing]=10

wmultiplier_table[hy_python_hw]=4000
wmultiplier_table[cr_python_hw]=4000
wmultiplier_table[kn_python_hw]=4000
wmultiplier_table[hy_python_mst]=1000
wmultiplier_table[cr_python_mst]=1000
wmultiplier_table[kn_python_mst]=1000
wmultiplier_table[hy_python_bfs]=1000
wmultiplier_table[cr_python_bfs]=1000
wmultiplier_table[kn_python_bfs]=1000
wmultiplier_table[hy_python_pagerank]=100
wmultiplier_table[cr_python_pagerank]=100
wmultiplier_table[kn_python_pagerank]=100
wmultiplier_table[hy_python_dna]=100
wmultiplier_table[cr_python_dna]=100
wmultiplier_table[kn_python_dna]=100
wmultiplier_table[hy_python_classify]=1
wmultiplier_table[cr_python_classify]=8
wmultiplier_table[kn_python_classify]=8
wmultiplier_table[hy_python_dynamichtml]=500
wmultiplier_table[cr_python_dynamichtml]=500
wmultiplier_table[kn_python_dynamichtml]=500
wmultiplier_table[hy_python_compression]=256
wmultiplier_table[cr_python_compression]=256
wmultiplier_table[kn_python_compression]=256
wmultiplier_table[hy_python_thumbnail]=1000
wmultiplier_table[cr_python_thumbnail]=1000
wmultiplier_table[kn_python_thumbnail]=1000
wmultiplier_table[hy_python_videoprocessing]=100
wmultiplier_table[cr_python_videoprocessing]=100
wmultiplier_table[kn_python_videoprocessing]=100
wmultiplier_table[hy_python_uploader]=500
wmultiplier_table[cr_python_uploader]=500
wmultiplier_table[kn_python_uploader]=500

wmultiplier_table[hy_javascript_hw]=16000
wmultiplier_table[cr_javascript_hw]=16000
wmultiplier_table[kn_javascript_hw]=16000
wmultiplier_table[hy_javascript_dynamichtml]=16000
wmultiplier_table[cr_javascript_dynamichtml]=16000
wmultiplier_table[kn_javascript_dynamichtml]=16000
wmultiplier_table[hy_javascript_thumbnail]=2048
wmultiplier_table[cr_javascript_thumbnail]=2048
wmultiplier_table[kn_javascript_thumbnail]=2048
wmultiplier_table[hy_javascript_uploader]=2048
wmultiplier_table[cr_javascript_uploader]=2048
wmultiplier_table[kn_javascript_uploader]=2048

declare -A concurrency_table
concurrency_table[hy_java_hw]=8
concurrency_table[hy_java_filehashing]=8
concurrency_table[hy_java_classify]=1
concurrency_table[hy_java_httprequest]=8
concurrency_table[hy_java_videoprocessing]=1

concurrency_table[hy_python_hw]=8
concurrency_table[hy_python_mst]=8
concurrency_table[hy_python_bfs]=8
concurrency_table[hy_python_pagerank]=1
concurrency_table[hy_python_dna]=8
concurrency_table[hy_python_classify]=1
concurrency_table[hy_python_dynamichtml]=4   # Changed from 8 to 4 because of high memory consumption.
concurrency_table[hy_python_compression]=8
concurrency_table[hy_python_thumbnail]=2
concurrency_table[hy_python_videoprocessing]=2
concurrency_table[hy_python_uploader]=4   # Changed from 8 to 4 because of high memory consumption.

concurrency_table[hy_javascript_hw]=8
concurrency_table[hy_javascript_dynamichtml]=8
concurrency_table[hy_javascript_thumbnail]=4
concurrency_table[hy_javascript_uploader]=8

# Knative concurrency.
concurrency_table[kn_java_hw]=4
concurrency_table[kn_java_filehashing]=2
concurrency_table[kn_java_classify]=1
concurrency_table[kn_java_httprequest]=4
concurrency_table[kn_java_videoprocessing]=1

concurrency_table[kn_python_hw]=8   # Could be 1 or 8 - there is some degradation but on w=8 doesn't exceed 30ms
concurrency_table[kn_python_mst]=8   # Could be 1 or 8 - there is some degradation but on w=8 doesn't exceed 30ms
concurrency_table[kn_python_bfs]=8   # Could be 1 or 8 - there is some degradation but on w=8 doesn't exceed 30ms
concurrency_table[kn_python_pagerank]=1
concurrency_table[kn_python_dna]=1
concurrency_table[kn_python_dynamichtml]=2
concurrency_table[kn_python_compression]=2
concurrency_table[kn_python_thumbnail]=2
concurrency_table[kn_python_videoprocessing]=2
concurrency_table[kn_python_uploader]=2

concurrency_table[kn_javascript_hw]=8
concurrency_table[kn_javascript_dynamichtml]=8
concurrency_table[kn_javascript_thumbnail]=4
concurrency_table[kn_javascript_uploader]=4

declare -A mem_table
declare -A cpu_table
mem_table[hy_java_hw]=256
mem_table[cr_java_hw]=256
mem_table[kn_java_hw]=512
cpu_table[hy_java_hw]=12500
cpu_table[cr_java_hw]=12500
cpu_table[kn_java_hw]=25000
mem_table[hy_java_filehashing]=256
mem_table[cr_java_filehashing]=256
mem_table[kn_java_filehashing]=1024
cpu_table[hy_java_filehashing]=12500
cpu_table[cr_java_filehashing]=12500
cpu_table[kn_java_filehashing]=50000
mem_table[hy_java_classify]=2048
mem_table[cr_java_classify]=2048
mem_table[kn_java_classify]=2048
cpu_table[hy_java_classify]=100000
cpu_table[cr_java_classify]=100000
cpu_table[kn_java_classify]=100000
mem_table[hy_java_httprequest]=256
mem_table[cr_java_httprequest]=256
mem_table[kn_java_httprequest]=512
cpu_table[hy_java_httprequest]=12500
cpu_table[cr_java_httprequest]=12500
cpu_table[kn_java_httprequest]=25000
mem_table[hy_java_videoprocessing]=2048
mem_table[cr_java_videoprocessing]=2048
mem_table[kn_java_videoprocessing]=2048
cpu_table[hy_java_videoprocessing]=100000
cpu_table[cr_java_videoprocessing]=100000
cpu_table[kn_java_videoprocessing]=100000

mem_table[hy_python_hw]=256
mem_table[cr_python_hw]=256
mem_table[kn_python_hw]=2048
cpu_table[hy_python_hw]=12500
cpu_table[cr_python_hw]=12500
cpu_table[kn_python_hw]=100000
mem_table[hy_python_mst]=256
mem_table[cr_python_mst]=256
mem_table[kn_python_mst]=2048
cpu_table[hy_python_mst]=12500
cpu_table[cr_python_mst]=12500
cpu_table[kn_python_mst]=100000
mem_table[hy_python_bfs]=256
mem_table[cr_python_bfs]=256
mem_table[kn_python_bfs]=2048
cpu_table[hy_python_bfs]=12500
cpu_table[cr_python_bfs]=12500
cpu_table[kn_python_bfs]=100000
mem_table[hy_python_pagerank]=256
mem_table[cr_python_pagerank]=256
mem_table[kn_python_pagerank]=2048
cpu_table[hy_python_pagerank]=12500
cpu_table[cr_python_pagerank]=12500
cpu_table[kn_python_pagerank]=100000
mem_table[hy_python_dna]=256
mem_table[cr_python_dna]=256
mem_table[kn_python_dna]=2048
cpu_table[hy_python_dna]=12500
cpu_table[cr_python_dna]=12500
cpu_table[kn_python_dna]=100000
mem_table[hy_python_classify]=2048
mem_table[cr_python_classify]=2048
# (not supported) mem_table[kn_python_classify]=
cpu_table[hy_python_classify]=100000
cpu_table[cr_python_classify]=100000
# (not supported) cpu_table[kn_python_classify]=
mem_table[hy_python_dynamichtml]=256
mem_table[cr_python_dynamichtml]=256
mem_table[kn_python_dynamichtml]=1024
cpu_table[hy_python_dynamichtml]=12500
cpu_table[cr_python_dynamichtml]=12500
cpu_table[kn_python_dynamichtml]=50000
mem_table[hy_python_compression]=256
mem_table[cr_python_compression]=256
mem_table[kn_python_compression]=2048
cpu_table[hy_python_compression]=12500
cpu_table[cr_python_compression]=12500
cpu_table[kn_python_compression]=100000
mem_table[hy_python_thumbnail]=1024
mem_table[cr_python_thumbnail]=256 # TODO - diff
mem_table[kn_python_thumbnail]=1024
cpu_table[hy_python_thumbnail]=50000
cpu_table[cr_python_thumbnail]=12500 # TODO - diff
cpu_table[kn_python_thumbnail]=50000
mem_table[hy_python_videoprocessing]=2048
mem_table[cr_python_videoprocessing]=2048
mem_table[kn_python_videoprocessing]=2048
cpu_table[hy_python_videoprocessing]=100000
cpu_table[cr_python_videoprocessing]=100000
cpu_table[kn_python_videoprocessing]=100000
mem_table[hy_python_uploader]=256
mem_table[cr_python_uploader]=256
mem_table[kn_python_uploader]=1024
cpu_table[hy_python_uploader]=12500
cpu_table[cr_python_uploader]=12500
cpu_table[kn_python_uploader]=50000

mem_table[hy_javascript_hw]=256
mem_table[cr_javascript_hw]=256
mem_table[kn_javascript_hw]=256
cpu_table[hy_javascript_hw]=12500
cpu_table[cr_javascript_hw]=12500
cpu_table[kn_javascript_hw]=12500
mem_table[hy_javascript_dynamichtml]=256
mem_table[cr_javascript_dynamichtml]=256
mem_table[kn_javascript_dynamichtml]=256
cpu_table[hy_javascript_dynamichtml]=12500
cpu_table[cr_javascript_dynamichtml]=12500
cpu_table[kn_javascript_dynamichtml]=12500
mem_table[hy_javascript_thumbnail]=512
mem_table[cr_javascript_thumbnail]=512
mem_table[kn_javascript_thumbnail]=512
cpu_table[hy_javascript_thumbnail]=25000
cpu_table[cr_javascript_thumbnail]=25000
cpu_table[kn_javascript_thumbnail]=25000
mem_table[hy_javascript_uploader]=256
mem_table[cr_javascript_uploader]=256
mem_table[kn_javascript_uploader]=512
cpu_table[hy_javascript_uploader]=12500
cpu_table[cr_javascript_uploader]=12500
cpu_table[kn_javascript_uploader]=25000

function hy_upload_function {
    curl -s -X POST $IP:$HYDRA_PORT/register?name=$APP_NAME\&url=$APP_URL\&entryPoint=$APP_MAIN\&language=$APP_LANG\&sandbox=$SANDBOX
    # Note: this is just to enter a new line after curl's output.
    echo ""
}

function hy_java_hw {
    APP_LANG=java
    APP_NAME=hy-jv-hello-world
    APP_MAIN=com.hello_world.HelloWorld
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-jv-hello-world","async":"false","cached":"true","arguments":""}' > $RUN_POST
    hy_upload_function
}

function hy_java_shopcart {
    APP_LANG=java
    APP_NAME=hy-jv-shopcart
    APP_MAIN=micronaut.benchmark.shopcart.Application
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-jv-shopcart","async":"false","cached":"true","arguments":""}' > $RUN_POST
    hy_upload_function
}

function cr_java_hw {
    IMG=docker.io/openwhisk/java8action:latest
    APP_LANG=java
    APP_NAME=cr-hello-world
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
}

function ph_java_hw {
    IMG=docker.io/sergiyivan/large-scale-experiment:photons
    APP_LANG=java
    APP_NAME=cr-hello-world
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    APP_NAME=ph-hello-world
}

function hy_javascript_hw {
    APP_LANG=java
    APP_NAME=hy-js-hello-world
    APP_MAIN=com.helloworld.HelloWorld
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-js-hello-world","async":"false","arguments":""}' > $RUN_POST
    hy_upload_function
}


function cr_javascript_hw {
    IMG=docker.io/openwhisk/action-nodejs-v12:latest
    APP_LANG=javascript
    APP_NAME=cr-hello-world
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run2.json
}

function hy_python_hw {
    APP_LANG=java
    APP_NAME=hy-py-hello-world
    APP_MAIN=com.helloworld.HelloWorld
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-hello-world","async":"false","arguments":""}' > $RUN_POST
    hy_upload_function
}

function cr_python_hw {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-hello-world
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run2.json
}

function hy_python_thumbnail {
    APP_LANG=java
    APP_NAME=hy-py-thumbnail
    APP_MAIN=com.thumbnail.Thumbnail
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-thumbnail","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_python_thumbnail {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-thumbnail
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function hy_javascript_thumbnail {
    APP_LANG=java
    APP_NAME=hy-js-thumbnail
    APP_MAIN=com.thumbnail.Thumbnail
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.zip"
    echo '{"name":"hy-js-thumbnail","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_javascript_thumbnail {
    IMG=docker.io/openwhisk/action-nodejs-v12:latest
    APP_LANG=javascript
    APP_NAME=cr-thumbnail
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function hy_java_genericapp {
    APP_LANG=java
    APP_NAME=hy-jv-genericapp
    APP_MAIN=com.genericapp.GenericApp
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-jv-genericapp","async":"false","arguments":"{\"memory\":\"4000000\",\"duration\":\"1000\"}"}' > $RUN_POST
    hy_upload_function
}

function hy_java_sleep {
    APP_LANG=java
    APP_NAME=hy-jv-sleep
    APP_MAIN=com.sleep.Sleep
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-jv-sleep","async":"false","arguments":"{\"memory\":\"128\",\"sleep\":\"1000\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_java_sleep {
    IMG=docker.io/openwhisk/java8action:latest
    APP_LANG=java
    APP_NAME=cr-sleep
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
}

function hy_python_sleep {
    APP_LANG=java
    APP_NAME=hy-py-sleep
    APP_MAIN=com.sleep.Sleep
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-sleep","async":"false","arguments":"1"}' > $RUN_POST
    hy_upload_function
}

function cr_python_sleep {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-sleep
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
}

function hy_javascript_sleep {
    APP_LANG=java
    APP_NAME=hy-js-sleep
    APP_MAIN=com.sleep.Sleep
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-js-sleep","async":"false","arguments":"{\"time\":\"1\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_javascript_sleep {
    IMG=docker.io/openwhisk/action-nodejs-v12:latest
    APP_LANG=javascript
    APP_NAME=cr-sleep
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
}

function hy_java_filehashing {
    APP_LANG=java
    APP_NAME=hy-jv-file-hashing
    APP_MAIN=com.filehashing.FileHashing
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-jv-file-hashing","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_java_filehashing {
    IMG=docker.io/openwhisk/java8action:latest
    APP_LANG=java
    APP_NAME=cr-file-hashing
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function ph_java_filehashing {
    IMG=docker.io/sergiyivan/large-scale-experiment:photons
    APP_LANG=java
    APP_NAME=cr-file-hashing
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
    APP_NAME=ph-file-hashing
}

function hy_java_httprequest {
    APP_LANG=java
    APP_NAME=hy-jv-httprequest
    APP_MAIN=com.httprequest.HttpRequest
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-jv-httprequest","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_java_httprequest {
    IMG=docker.io/openwhisk/java8action:latest
    APP_LANG=java
    APP_NAME=cr-httprequest
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function ph_java_httprequest {
    IMG=docker.io/sergiyivan/large-scale-experiment:photons
    APP_LANG=java
    APP_NAME=cr-httprequest
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
    APP_NAME=ph-httprequest
}

function hy_java_videoprocessing {
    APP_LANG=java
    APP_NAME=hy-jv-video-processing
    APP_MAIN=com.videoprocessing.VideoProcessing
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-jv-video-processing","async":"false","arguments":"{\"video\":\"http://'$DATA_IP':'$DATA_PORT'/video.mp4\",\"ffmpeg\":\"http://'$DATA_IP':'$DATA_PORT'/ffmpeg\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_java_videoprocessing {
    IMG=docker.io/openwhisk/java8action:latest
    APP_LANG=java
    APP_NAME=cr-video-processing
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "ffmpeg_url": "http://'$DATA_IP':'$DATA_PORT'/ffmpeg", "video_url": "http://'$DATA_IP':'$DATA_PORT'/video.mp4" } }' > $RUN_POST
}

function ph_java_videoprocessing {
    IMG=docker.io/sergiyivan/large-scale-experiment:photons
    APP_LANG=java
    APP_NAME=cr-video-processing
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "ffmpeg_url": "http://'$DATA_IP':'$DATA_PORT'/ffmpeg", "video_url": "http://'$DATA_IP':'$DATA_PORT'/video.mp4" } }' > $RUN_POST
    APP_NAME=ph-video-processing
}

function hy_python_videoprocessing {
    APP_LANG=java
    APP_NAME=hy-py-video-processing
    APP_MAIN=com.videoprocessing.VideoProcessing
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-video-processing","async":"false","arguments":"{\"video\":\"http://'$DATA_IP':'$DATA_PORT'/video.mp4\",\"ffmpeg\":\"http://'$DATA_IP':'$DATA_PORT'/ffmpeg\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_python_videoprocessing {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-video-processing
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "ffmpeg_url": "http://'$DATA_IP':'$DATA_PORT'/ffmpeg", "video_url": "http://'$DATA_IP':'$DATA_PORT'/video.mp4" } }' > $RUN_POST
}

function hy_java_classify {
    APP_LANG=java
    APP_NAME=hy-jv-classify
    APP_MAIN=com.classify.Classify
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.zip"
    echo '{"name":"hy-jv-classify","async":"false","arguments":"{\"model_url\":\"http://'$DATA_IP':'$DATA_PORT'/tensorflow_inception_graph.pb\",\"labels_url\":\"http://'$DATA_IP':'$DATA_PORT'/imagenet_comp_graph_label_strings.txt\",\"image_url\":\"http://'$DATA_IP':'$DATA_PORT'/eagle.jpg\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_java_classify {
    IMG=docker.io/openwhisk/java8action:latest
    APP_LANG=java
    APP_NAME=cr-classify
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "model_url": "http://'$DATA_IP':'$DATA_PORT'/tensorflow_inception_graph.pb", "labels_url": "http://'$DATA_IP':'$DATA_PORT'/imagenet_comp_graph_label_strings.txt", "image_url": "http://'$DATA_IP':'$DATA_PORT'/eagle.jpg" } }' > $RUN_POST
}

function ph_java_classify {
    IMG=docker.io/sergiyivan/large-scale-experiment:photons
    APP_LANG=java
    APP_NAME=cr-classify
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "model_url": "http://'$DATA_IP':'$DATA_PORT'/tensorflow_inception_graph.pb", "labels_url": "http://'$DATA_IP':'$DATA_PORT'/imagenet_comp_graph_label_strings.txt", "image_url": "http://'$DATA_IP':'$DATA_PORT'/eagle.jpg" } }' > $RUN_POST
    APP_NAME=ph-classify
}

function hy_python_compression {
    APP_LANG=java
    APP_NAME=hy-py-compression
    APP_MAIN=com.compression.Compression
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-compression","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/video.mp4\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_python_compression {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-compression
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/video.mp4" } }' > $RUN_POST
}

function hy_python_mst {
    APP_LANG=java
    APP_NAME=hy-py-mst
    APP_MAIN=com.mst.MST
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-mst","async":"false","arguments":"{\"size\":\"100\"}"}' > $RUN_POST
    hy_upload_function
}

function hy_python_bfs {
    APP_LANG=java
    APP_NAME=hy-py-bfs
    APP_MAIN=com.bfs.BFS
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-bfs","async":"false","arguments":"{\"size\":\"100\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_python_bfs {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-bfs
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "size": "100" } }' > $RUN_POST
}

function hy_python_pagerank {
    APP_LANG=java
    APP_NAME=hy-py-pagerank
    APP_MAIN=com.pr.PageRank
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-pagerank","async":"false","arguments":"{\"size\":\"10\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_python_pagerank {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-pagerank
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "size": "100" } }' > $RUN_POST
}

function hy_python_dna {
    APP_LANG=java
    APP_NAME=hy-py-dna
    APP_MAIN=com.dna.DNA
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-dna","async":"false","arguments":"{\"fasta_url\":\"http://'$DATA_IP':'$DATA_PORT'/bacillus_subtilis.fasta\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_python_dna {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-dna
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "fasta_url": "http://'$DATA_IP':'$DATA_PORT'/bacillus_subtilis.fasta" } }' > $RUN_POST
}

function hy_python_classify {
    APP_LANG=java
    APP_NAME=hy-py-classify
    APP_MAIN=com.classify.Classify
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-classify","async":"false","arguments":"{\"restnet_url\":\"http://'$DATA_IP':'$DATA_PORT'/resnet50-19c8e357.pth\",\"img_url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_python_classify {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-classify
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "restnet_url": "http://'$DATA_IP':'$DATA_PORT'/resnet50-19c8e357.pth", "img_url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function cr_python_mst {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-mst
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "size": "100" } }' > $RUN_POST
}

function hy_javascript_dynamichtml {
    APP_LANG=java
    APP_NAME=hy-js-dynamic-html
    APP_MAIN=com.dynamichtml.DynamicHTML
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-js-dynamic-html","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/template.html\",\"username\":\"rbruno\",\"nsize\":\"10\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_javascript_dynamichtml {
    IMG=docker.io/openwhisk/action-nodejs-v12:latest
    APP_LANG=javascript
    APP_NAME=cr-dynamic-html
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/template.html", "username": "rbruno", "nsize": "10" } }' > $RUN_POST
}

function hy_python_dynamichtml {
    APP_LANG=java
    APP_NAME=hy-py-dynamic-html
    APP_MAIN=com.dynamichtml.DynamicHTML
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-dynamic-html","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/template.html\",\"username\":\"rbruno\",\"nsize\":\"10\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_python_dynamichtml {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-dynamic-html
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/template.html", "username": "rbruno", "nsize": "10" } }' > $RUN_POST
}

function hy_python_uploader {
    APP_LANG=java
    APP_NAME=hy-py-uploader
    APP_MAIN=com.uploader.Uploader
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-py-uploader","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_python_uploader {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-uploader
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function hy_javascript_uploader {
    APP_LANG=java
    APP_NAME=hy-js-uploader
    APP_MAIN=com.uploader.Uploader
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"hy-js-uploader","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    hy_upload_function
}

function cr_javascript_uploader {
    IMG=docker.io/openwhisk/action-nodejs-v12:latest
    APP_LANG=javascript
    APP_NAME=cr-uploader
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function gh_java_http {
    APP_PORT=9001
    APP_LANG=java
    APP_NAME=gh-http-hello-world
    APP_PATH=helloworld
    app=$BENCHMARKS_HOME/src/java/gh-http-hello-world/build/native/nativeCompile/simple-http

    echo "Loading $app..." | tee -a $TDIR/backend.log
    sas=$(date +%s%N)
    curl --data-binary '{ "act": "add_ep", "app": "'$app'", "ep": 2001, "default_socket": { "port": '$APP_PORT'  }, "listen_socket": { "port": '$APP_PORT'  }, "fsroot": "/", "fsmappings": [ { "concrete": "/   ", "virt": "/"  }  ], "env": { "myvar": "initial_value"  }, "instances": 1  }' http://$IP:$GRAALHOST_PORT/command

    # Let the app load.
    wait_port $IP $APP_PORT

    # Measure how long it took to accept connections.
    sat=$((($(date +%s%N) - $sbs)/1000))
    echo "Loading $app... done (took $sbt us)." | tee -a $TDIR/backend.log
}

function kn_java_hw {
    IMG=knative-jv/kn-hello-world
    APP_LANG=java
    APP_NAME=kn-hello-world
    echo '{ "name": "world" }' > $RUN_POST
}

function kn_java_filehashing {
    IMG=knative-jv/kn-file-hashing
    APP_LANG=java
    APP_NAME=kn-file-hashing
    echo '{ "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" }' > $RUN_POST
}

function kn_java_classify {
    IMG=knative-jv/kn-classify
    APP_LANG=java
    APP_NAME=kn-classify
    echo '{ "model_url": "http://'$DATA_IP':'$DATA_PORT'/tensorflow_inception_graph.pb", "labels_url": "http://'$DATA_IP':'$DATA_PORT'/imagenet_comp_graph_label_strings.txt", "image_url": "http://'$DATA_IP':'$DATA_PORT'/eagle.jpg" }' > $RUN_POST
}

function kn_java_httprequest {
    IMG=knative-jv/kn-httprequest
    APP_LANG=java
    APP_NAME=kn-httprequest
    echo '{ "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" }' > $RUN_POST
}

function kn_java_videoprocessing {
    IMG=knative-jv/kn-video-processing
    APP_LANG=java
    APP_NAME=kn-video-processing
    echo '{ "ffmpeg": "http://'$DATA_IP':'$DATA_PORT'/ffmpeg", "video": "http://'$DATA_IP':'$DATA_PORT'/video.mp4" }' > $RUN_POST
}

function kn_javascript_hw {
    IMG=knative-js/kn-hello-world
    APP_LANG=javascript
    APP_NAME=kn-hello-world
    echo '{ }' > $RUN_POST
}

function kn_javascript_dynamichtml {
    IMG=knative-js/kn-dynamic-html
    APP_LANG=javascript
    APP_NAME=kn-dynamic-html
    echo '{ "url": "http://'$DATA_IP':'$DATA_PORT'/template.html", "username": "rbruno", "nsize": "10" }' > $RUN_POST
}

function kn_javascript_thumbnail {
    IMG=knative-js/kn-thumbnail
    APP_LANG=javascript
    APP_NAME=kn-thumbnail
    echo '{ "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" }' > $RUN_POST
}

function kn_javascript_uploader {
    IMG=knative-js/kn-uploader
    APP_LANG=javascript
    APP_NAME=kn-uploader
    echo '{ "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" }' > $RUN_POST
}

function kn_python_hw {
    IMG=knative-py/kn-hello-world
    APP_LANG=python
    APP_NAME=kn-hello-world
    echo '{ }' > $RUN_POST
}

function kn_python_mst {
    IMG=knative-py/kn-mst
    APP_LANG=python
    APP_NAME=kn-mst
    echo '{ "size": "100" }' > $RUN_POST
}

function kn_python_bfs {
    IMG=knative-py/kn-bfs
    APP_LANG=python
    APP_NAME=kn-bfs
    echo '{ "size": "100" }' > $RUN_POST
}

function kn_python_pagerank {
    IMG=knative-py/kn-pagerank
    APP_LANG=python
    APP_NAME=kn-pagerank
    echo '{ "size": "100" }' > $RUN_POST
}

function kn_python_dna {
    IMG=knative-py/kn-dna
    APP_LANG=python
    APP_NAME=kn-dna
    echo '{ "fasta_url": "http://'$DATA_IP':'$DATA_PORT'/bacillus_subtilis.fasta" }' > $RUN_POST
}

function kn_python_dynamichtml {
    IMG=knative-py/kn-dynamic-html
    APP_LANG=python
    APP_NAME=kn-dynamic-html
    echo '{ "url": "http://'$DATA_IP':'$DATA_PORT'/template.html", "username": "rbruno", "nsize": "10" }' > $RUN_POST
}

function kn_python_compression {
    IMG=knative-py/kn-compression
    APP_LANG=python
    APP_NAME=kn-compression
    echo '{ "url": "http://'$DATA_IP':'$DATA_PORT'/video.mp4" }' > $RUN_POST
}

function kn_python_thumbnail {
    IMG=knative-py/kn-thumbnail
    APP_LANG=python
    APP_NAME=kn-thumbnail
    echo '{ "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" }' > $RUN_POST
}

function kn_python_videoprocessing {
    IMG=knative-py/kn-video-processing
    APP_LANG=python
    APP_NAME=kn-video-processing
    echo '{ "ffmpeg": "http://'$DATA_IP':'$DATA_PORT'/ffmpeg", "video": "http://'$DATA_IP':'$DATA_PORT'/video.mp4" }' > $RUN_POST
}

function kn_python_uploader {
    IMG=knative-py/kn-uploader
    APP_LANG=python
    APP_NAME=kn-uploader
    echo '{ "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" }' > $RUN_POST
}
