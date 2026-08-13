#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LEGACY_DATA_DIR="$DIR/../data"
APPS_DIR="$DIR/../data/apps"
WEB_ROOT="/tmp/benchmark-webroot"

cd "$DIR"

# Check and download required files if they don't exist
if [ ! -f bacillus_subtilis.fasta ]; then
    echo "Downloading bacillus_subtilis.fasta..."
    wget https://github.com/spcl/serverless-benchmarks-data/raw/6a17a460f289e166abb47ea6298fb939e80e8beb/500.scientific/504.dna-visualisation/bacillus_subtilis.fasta
fi

if [ ! -f resnet50.onnx ]; then
    echo "Downloading resnet50.onnx..."
    wget https://github.com/onnx/models/raw/main/validated/vision/classification/resnet/model/resnet50-v1-7.onnx -O resnet50.onnx
fi

if [ ! -f tensorflow_inception_graph.pb ]; then
    echo "Downloading tensorflow_inception_graph.pb..."
    wget https://github.com/martinwicke/tensorflow-tutorial/raw/master/tensorflow_inception_graph.pb
fi

if [ ! -f ffmpeg ]; then
    echo "Downloading ffmpeg..."
    wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
    tar -xf ffmpeg-release-amd64-static.tar.xz
    mv ffmpeg-*-amd64-static/ffmpeg .
    rm -r ffmpeg-*-amd64-static
    rm ffmpeg-release-amd64-static.tar.xz
fi

# Ensure the local video file is present
if [ ! -f video.mp4 ]; then
    echo "Error: video.mp4 not found in $DIR."
    echo "Please place your local video file here and rename it to 'video.mp4'."
    exit 1
fi

if [ ! -d "$APPS_DIR" ]; then
    echo "Error: benchmark apps directory not found at $APPS_DIR."
    echo "Build/install the benchmark artifacts first."
    exit 1
fi

if [ ! -d "$LEGACY_DATA_DIR" ]; then
    echo "Error: legacy benchmark data directory not found at $LEGACY_DATA_DIR."
    exit 1
fi

rm -rf "$WEB_ROOT"
mkdir -p "$WEB_ROOT/apps"
cp -a "$LEGACY_DATA_DIR/." "$WEB_ROOT/"
cp -a "$DIR/." "$WEB_ROOT/"
cp -a "$APPS_DIR/." "$WEB_ROOT/apps/"

# Remove existing container if it exists
docker rm -f benchmark-web >/dev/null 2>&1 || true

# if [ ! -f ffmpeg ];
# then
#     wget "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-$FFMPEG_ARCH-static.tar.xz"
#     tar -xf "ffmpeg-release-$FFMPEG_ARCH-static.tar.xz"
#     mv ffmpeg-*-$FFMPEG_ARCH-static/ffmpeg .
#     rm -r ffmpeg-*-$FFMPEG_ARCH-static
#     rm "ffmpeg-release-$FFMPEG_ARCH-static.tar.xz"
#     # Installing into /tmp as video-processing benchmark expects the binary to be there.
#     cp ffmpeg /tmp/ffmpeg
# fi

# Start the Nginx container
docker run \
    -d \
    --rm \
    -p 8000:80 \
    --name benchmark-web \
    -v "$WEB_ROOT:/usr/share/nginx/html:ro" \
    nginx


docker rm -f web-uploader 
docker run -d -p 9696:8080 --rm --name web-uploader mayth/simple-upload-server -document_root=/docroot -addr=:8080 -max_upload_size=1048576001

echo "Webserver started"
echo
echo "Available files:"
echo "http://localhost:8000/template.html"
echo "http://localhost:8000/bacillus_subtilis.fasta"
echo "http://localhost:8000/tensorflow_inception_graph.pb"
echo "http://localhost:8000/imagenet_comp_graph_label_strings.txt"
echo "http://localhost:8000/resnet50.onnx"
echo "http://localhost:8000/video.mp4"
echo "http://localhost:8000/snap.png"
echo "http://localhost:8000/watermark.png"
echo "http://localhost:8000/new.mp4"
echo "http://localhost:8000/ffmpeg"
echo "http://localhost:8000/apps/hy-jv-hello-world.so"
echo "http://localhost:8000/apps/hello_world_guest.aot"
