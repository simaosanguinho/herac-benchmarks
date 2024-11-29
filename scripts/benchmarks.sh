#!/bin/bash

# Import global definitions.
source $(DIR)/globals.sh

# Data is available in the host ip.
DATA_IP=$(ip route get 8.8.8.8 | grep -oP  'src \K\S+')
DATA_PORT=8000

JV_GV_BENCHMARKS=""
# (disabled) #JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS gv_java_sleep"
# (disabled) #JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS gv_java_shopcart"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS gv_java_hw"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS gv_java_filehashing"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS gv_java_classify"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS gv_java_httprequest"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS gv_java_videoprocessing"

JV_CR_BENCHMARKS=""
# (disabled) #JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_sleep"
# (disabled) #JV_CR_BENCHMARKS="$JV_GV_BENCHMARKS cr_java_shopcart"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_hw"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_filehashing"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_classify"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_httprequest"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS cr_java_videoprocessing"

PY_GV_BENCHMARKS=""
# (disabled) #PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_sleep"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_hw"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_mst"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_bfs"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_pagerank"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_dna"
#PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_classify" # TODO - not working.
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_dynamichtml"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_compression"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_thumbnail"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_videoprocessing"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS gv_python_uploader"

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

JS_GV_BENCHMARKS=""
# (disabled) #JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS gv_javascript_sleep"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS gv_javascript_hw"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS gv_javascript_dynamichtml"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS gv_javascript_thumbnail"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS gv_javascript_uploader"

JS_CR_BENCHMARKS=""
# (disabled) #JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS cr_javascript_sleep"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS cr_javascript_hw"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS cr_javascript_dynamichtml"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS cr_javascript_thumbnail"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS cr_javascript_uploader"

GV_BENCHMARKS="$JV_GV_BENCHMARKS $PY_GV_BENCHMARKS $JS_GV_BENCHMARKS"
CR_BENCHMARKS="$JV_CR_BENCHMARKS $PY_CR_BENCHMARKS $JS_CR_BENCHMARKS"

# These values are recommended values for running each benchmark. These values
# are used when running experiments.
declare -A wmultiplier_table
wmultiplier_table[gv_java_hw]=2000
wmultiplier_table[cr_java_hw]=16000
wmultiplier_table[gv_java_filehashing]=2000
wmultiplier_table[cr_java_filehashing]=4000
wmultiplier_table[gv_java_classify]=10
wmultiplier_table[cr_java_classify]=10
wmultiplier_table[gv_java_httprequest]=1000
wmultiplier_table[cr_java_httprequest]=8000
wmultiplier_table[gv_java_videoprocessing]=2
wmultiplier_table[cr_java_videoprocessing]=2

wmultiplier_table[gv_python_hw]=500
wmultiplier_table[cr_python_hw]=4000
wmultiplier_table[gv_python_mst]=40
wmultiplier_table[cr_python_mst]=40
wmultiplier_table[gv_python_bfs]=40
wmultiplier_table[cr_python_bfs]=40
wmultiplier_table[gv_python_pagerank]=10
wmultiplier_table[cr_python_pagerank]=40
wmultiplier_table[gv_python_dna]=8
wmultiplier_table[cr_python_dna]=8
wmultiplier_table[gv_python_classify]=1
wmultiplier_table[cr_python_classify]=8
wmultiplier_table[gv_python_dynamichtml]=25
wmultiplier_table[cr_python_dynamichtml]=100
wmultiplier_table[gv_python_compression]=10
wmultiplier_table[cr_python_compression]=40
wmultiplier_table[gv_python_thumbnail]=10
wmultiplier_table[cr_python_thumbnail]=80
wmultiplier_table[gv_python_videoprocessing]=1
wmultiplier_table[cr_python_videoprocessing]=8
wmultiplier_table[gv_python_uploader]=10
wmultiplier_table[cr_python_uploader]=80

wmultiplier_table[gv_javascript_hw]=2000
wmultiplier_table[cr_javascript_hw]=16000
wmultiplier_table[gv_javascript_dynamichtml]=256
wmultiplier_table[cr_javascript_dynamichtml]=2048
wmultiplier_table[gv_javascript_thumbnail]=256
wmultiplier_table[cr_javascript_thumbnail]=2048
wmultiplier_table[gv_javascript_uploader]=256
wmultiplier_table[cr_javascript_uploader]=2048

declare -A concurrency_table
concurrency_table[gv_java_hw]=8
concurrency_table[gv_java_filehashing]=8
concurrency_table[gv_java_classify]=1
concurrency_table[gv_java_httprequest]=8
concurrency_table[gv_java_videoprocessing]=1

concurrency_table[gv_python_hw]=8
concurrency_table[gv_python_mst]=8
concurrency_table[gv_python_bfs]=8
concurrency_table[gv_python_pagerank]=1
concurrency_table[gv_python_dna]=8
concurrency_table[gv_python_classify]=1
concurrency_table[gv_python_dynamichtml]=8
concurrency_table[gv_python_compression]=8
concurrency_table[gv_python_thumbnail]=2
concurrency_table[gv_python_videoprocessing]=2
concurrency_table[gv_python_uploader]=8

concurrency_table[gv_javascript_hw]=8
concurrency_table[gv_javascript_dynamichtml]=8
concurrency_table[gv_javascript_thumbnail]=4
concurrency_table[gv_javascript_uploader]=8

declare -A mem_table
declare -A cpu_table
mem_table[gv_java_hw]=256
mem_table[cr_java_hw]=256
cpu_table[gv_java_hw]=12500
cpu_table[cr_java_hw]=12500
mem_table[gv_java_filehashing]=256
mem_table[cr_java_filehashing]=256
cpu_table[gv_java_filehashing]=12500
cpu_table[cr_java_filehashing]=12500
mem_table[gv_java_classify]=2048
mem_table[cr_java_classify]=2048
cpu_table[gv_java_classify]=100000
cpu_table[cr_java_classify]=100000
mem_table[gv_java_httprequest]=256
mem_table[cr_java_httprequest]=256
cpu_table[gv_java_httprequest]=12500
cpu_table[cr_java_httprequest]=12500
mem_table[gv_java_videoprocessing]=2048
mem_table[cr_java_videoprocessing]=2048
cpu_table[gv_java_videoprocessing]=100000
cpu_table[cr_java_videoprocessing]=100000

mem_table[gv_python_hw]=256
mem_table[cr_python_hw]=256
cpu_table[gv_python_hw]=12500
cpu_table[cr_python_hw]=12500
mem_table[gv_python_mst]=256
mem_table[cr_python_mst]=256
cpu_table[gv_python_mst]=12500
cpu_table[cr_python_mst]=12500
mem_table[gv_python_bfs]=256
mem_table[cr_python_bfs]=256
cpu_table[gv_python_bfs]=12500
cpu_table[cr_python_bfs]=12500
mem_table[gv_python_pagerank]=256
mem_table[cr_python_pagerank]=256
cpu_table[gv_python_pagerank]=12500
cpu_table[cr_python_pagerank]=12500
mem_table[gv_python_dna]=256
mem_table[cr_python_dna]=256
cpu_table[gv_python_dna]=12500
cpu_table[cr_python_dna]=12500
mem_table[gv_python_classify]=2048
mem_table[cr_python_classify]=2048
cpu_table[gv_python_classify]=100000
cpu_table[cr_python_classify]=100000
mem_table[gv_python_dynamichtml]=256
mem_table[cr_python_dynamichtml]=256
cpu_table[gv_python_dynamichtml]=12500
cpu_table[cr_python_dynamichtml]=12500
mem_table[gv_python_compression]=256
mem_table[cr_python_compression]=256
cpu_table[gv_python_compression]=12500
cpu_table[cr_python_compression]=12500
mem_table[gv_python_thumbnail]=1024
mem_table[cr_python_thumbnail]=256 # TODO - diff
cpu_table[gv_python_thumbnail]=50000
cpu_table[cr_python_thumbnail]=12500 # TODO - diff
mem_table[gv_python_videoprocessing]=2048
mem_table[cr_python_videoprocessing]=2048
cpu_table[gv_python_videoprocessing]=100000
cpu_table[cr_python_videoprocessing]=100000
mem_table[gv_python_uploader]=256
mem_table[cr_python_uploader]=256
cpu_table[gv_python_uploader]=12500
cpu_table[cr_python_uploader]=12500

mem_table[gv_javascript_hw]=256
mem_table[cr_javascript_hw]=256
cpu_table[gv_javascript_hw]=12500
cpu_table[cr_javascript_hw]=12500
mem_table[gv_javascript_dynamichtml]=256
mem_table[cr_javascript_dynamichtml]=256
cpu_table[gv_javascript_dynamichtml]=12500
cpu_table[cr_javascript_dynamichtml]=12500
mem_table[gv_javascript_thumbnail]=512
mem_table[cr_javascript_thumbnail]=512
cpu_table[gv_javascript_thumbnail]=25000
cpu_table[cr_javascript_thumbnail]=25000
mem_table[gv_javascript_uploader]=256
mem_table[cr_javascript_uploader]=256
cpu_table[gv_javascript_uploader]=12500
cpu_table[cr_javascript_uploader]=12500

function gv_upload_function {
    curl -s -X POST $IP:$GRAALVISOR_PORT/register?name=$APP_NAME\&url=$APP_URL\&entryPoint=$APP_MAIN\&language=$APP_LANG\&sandbox=$SANDBOX
    # Note: this is just to enter a new line after curl's output.
    echo ""
}

function gv_java_hw {
    APP_LANG=java
    APP_NAME=gv-jv-hello-world
    APP_MAIN=com.hello_world.HelloWorld
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-jv-hello-world","async":"false","cached":"true","arguments":""}' > $RUN_POST
    gv_upload_function
}

function gv_java_shopcart {
    APP_LANG=java
    APP_NAME=gv-jv-shopcart
    APP_MAIN=micronaut.benchmark.shopcart.Application
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-jv-shopcart","async":"false","cached":"true","arguments":""}' > $RUN_POST
    gv_upload_function
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

function gv_javascript_hw {
    APP_LANG=java
    APP_NAME=gv-js-hello-world
    APP_MAIN=com.helloworld.HelloWorld
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-js-hello-world","async":"false","arguments":""}' > $RUN_POST
    gv_upload_function
}


function cr_javascript_hw {
    IMG=docker.io/openwhisk/action-nodejs-v12:latest
    APP_LANG=javascript
    APP_NAME=cr-hello-world
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run2.json
}

function gv_python_hw {
    APP_LANG=java
    APP_NAME=gv-py-hello-world
    APP_MAIN=com.helloworld.HelloWorld
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-hello-world","async":"false","arguments":""}' > $RUN_POST
    gv_upload_function
}

function cr_python_hw {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-hello-world
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run2.json
}

function gv_python_thumbnail {
    APP_LANG=java
    APP_NAME=gv-py-thumbnail
    APP_MAIN=com.thumbnail.Thumbnail
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-thumbnail","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_python_thumbnail {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-thumbnail
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function gv_javascript_thumbnail {
    APP_LANG=java
    APP_NAME=gv-js-thumbnail
    APP_MAIN=com.thumbnail.Thumbnail
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.zip"
    echo '{"name":"gv-js-thumbnail","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_javascript_thumbnail {
    IMG=docker.io/openwhisk/action-nodejs-v12:latest
    APP_LANG=javascript
    APP_NAME=cr-thumbnail
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function gv_java_genericapp {
    APP_LANG=java
    APP_NAME=gv-jv-genericapp
    APP_MAIN=com.genericapp.GenericApp
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-jv-genericapp","async":"false","arguments":"{\"memory\":\"4000000\",\"duration\":\"1000\"}"}' > $RUN_POST
    gv_upload_function
}

function gv_java_sleep {
    APP_LANG=java
    APP_NAME=gv-jv-sleep
    APP_MAIN=com.sleep.Sleep
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-jv-sleep","async":"false","arguments":"{\"memory\":\"128\",\"sleep\":\"1000\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_java_sleep {
    IMG=docker.io/openwhisk/java8action:latest
    APP_LANG=java
    APP_NAME=cr-sleep
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
}

function gv_python_sleep {
    APP_LANG=java
    APP_NAME=gv-py-sleep
    APP_MAIN=com.sleep.Sleep
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-sleep","async":"false","arguments":"1"}' > $RUN_POST
    gv_upload_function
}

function cr_python_sleep {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-sleep
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
}

function gv_javascript_sleep {
    APP_LANG=java
    APP_NAME=gv-js-sleep
    APP_MAIN=com.sleep.Sleep
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-js-sleep","async":"false","arguments":"{\"time\":\"1\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_javascript_sleep {
    IMG=docker.io/openwhisk/action-nodejs-v12:latest
    APP_LANG=javascript
    APP_NAME=cr-sleep
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
}

function gv_java_filehashing {
    APP_LANG=java
    APP_NAME=gv-jv-file-hashing
    APP_MAIN=com.filehashing.FileHashing
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-jv-file-hashing","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    gv_upload_function
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

function gv_java_httprequest {
    APP_LANG=java
    APP_NAME=gv-jv-httprequest
    APP_MAIN=com.httprequest.HttpRequest
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-jv-httprequest","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    gv_upload_function
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

function gv_java_videoprocessing {
    APP_LANG=java
    APP_NAME=gv-jv-video-processing
    APP_MAIN=com.videoprocessing.VideoProcessing
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-jv-video-processing","async":"false","arguments":"{\"video\":\"http://'$DATA_IP':'$DATA_PORT'/video.mp4\",\"ffmpeg\":\"http://'$DATA_IP':'$DATA_PORT'/ffmpeg\"}"}' > $RUN_POST
    gv_upload_function
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

function gv_python_videoprocessing {
    APP_LANG=java
    APP_NAME=gv-py-video-processing
    APP_MAIN=com.videoprocessing.VideoProcessing
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-video-processing","async":"false","arguments":"{\"video\":\"http://'$DATA_IP':'$DATA_PORT'/video.mp4\",\"ffmpeg\":\"http://'$DATA_IP':'$DATA_PORT'/ffmpeg\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_python_videoprocessing {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-video-processing
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "ffmpeg_url": "http://'$DATA_IP':'$DATA_PORT'/ffmpeg", "video_url": "http://'$DATA_IP':'$DATA_PORT'/video.mp4" } }' > $RUN_POST
}

function gv_java_classify {
    APP_LANG=java
    APP_NAME=gv-jv-classify
    APP_MAIN=com.classify.Classify
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.zip"
    echo '{"name":"gv-jv-classify","async":"false","arguments":"{\"model_url\":\"http://'$DATA_IP':'$DATA_PORT'/tensorflow_inception_graph.pb\",\"labels_url\":\"http://'$DATA_IP':'$DATA_PORT'/imagenet_comp_graph_label_strings.txt\",\"image_url\":\"http://'$DATA_IP':'$DATA_PORT'/eagle.jpg\"}"}' > $RUN_POST
    gv_upload_function
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

function gv_python_compression {
    APP_LANG=java
    APP_NAME=gv-py-compression
    APP_MAIN=com.compression.Compression
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-compression","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/video.mp4\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_python_compression {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-compression
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function gv_python_mst {
    APP_LANG=java
    APP_NAME=gv-py-mst
    APP_MAIN=com.mst.MST
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-mst","async":"false","arguments":"{\"size\":\"100\"}"}' > $RUN_POST
    gv_upload_function
}

function gv_python_bfs {
    APP_LANG=java
    APP_NAME=gv-py-bfs
    APP_MAIN=com.bfs.BFS
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-bfs","async":"false","arguments":"{\"size\":\"100\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_python_bfs {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-bfs
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "size": "100" } }' > $RUN_POST
}

function gv_python_pagerank {
    APP_LANG=java
    APP_NAME=gv-py-pagerank
    APP_MAIN=com.pr.PageRank
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-pagerank","async":"false","arguments":"{\"size\":\"10\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_python_pagerank {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-pagerank
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "size": "100" } }' > $RUN_POST
}

function gv_python_dna {
    APP_LANG=java
    APP_NAME=gv-py-dna
    APP_MAIN=com.dna.DNA
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-dna","async":"false","arguments":"{\"fasta_url\":\"http://'$DATA_IP':'$DATA_PORT'/bacillus_subtilis.fasta\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_python_dna {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-dna
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "fasta_url": "http://'$DATA_IP':'$DATA_PORT'/bacillus_subtilis.fasta" } }' > $RUN_POST
}

function gv_python_classify {
    APP_LANG=java
    APP_NAME=gv-py-classify
    APP_MAIN=com.classify.Classify
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-classify","async":"false","arguments":"{\"restnet_url\":\"http://'$DATA_IP':'$DATA_PORT'/resnet50-19c8e357.pth\",\"img_url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    gv_upload_function
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

function gv_javascript_dynamichtml {
    APP_LANG=java
    APP_NAME=gv-js-dynamic-html
    APP_MAIN=com.dynamichtml.DynamicHTML
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-js-dynamic-html","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/template.html\",\"username\":\"rbruno\",\"nsize\":\"10\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_javascript_dynamichtml {
    IMG=docker.io/openwhisk/action-nodejs-v12:latest
    APP_LANG=javascript
    APP_NAME=cr-dynamic-html
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/template.html", "username": "rbruno", "nsize": "10" } }' > $RUN_POST
}

function gv_python_dynamichtml {
    APP_LANG=java
    APP_NAME=gv-py-dynamic-html
    APP_MAIN=com.dynamichtml.DynamicHTML
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-dynamic-html","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/template.html\",\"username\":\"rbruno\",\"nsize\":\"10\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_python_dynamichtml {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-dynamic-html
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/template.html", "username": "rbruno", "nsize": "10" } }' > $RUN_POST
}

function gv_python_uploader {
    APP_LANG=java
    APP_NAME=gv-py-uploader
    APP_MAIN=com.uploader.Uploader
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-py-uploader","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_python_uploader {
    IMG=docker.io/openwhisk/action-python-v3.9:latest
    APP_LANG=python
    APP_NAME=cr-uploader
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}

function gv_javascript_uploader {
    APP_LANG=java
    APP_NAME=gv-js-uploader
    APP_MAIN=com.uploader.Uploader
    APP_URL="http://$DATA_IP:$DATA_PORT/apps/$APP_NAME.so"
    echo '{"name":"gv-js-uploader","async":"false","arguments":"{\"url\":\"http://'$DATA_IP':'$DATA_PORT'/snap.png\"}"}' > $RUN_POST
    gv_upload_function
}

function cr_javascript_uploader {
    IMG=docker.io/openwhisk/action-nodejs-v12:latest
    APP_LANG=javascript
    APP_NAME=cr-uploader
    INIT_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/init.json
    RUN_POST=$BENCHMARKS_HOME/src/$APP_LANG/$APP_NAME/run.json
    echo '{ "value": { "url": "http://'$DATA_IP':'$DATA_PORT'/snap.png" } }' > $RUN_POST
}
