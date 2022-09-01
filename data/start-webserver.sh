#!/bin/bash

#docker run -it --network host --rm -p 8080:8000 -v /home/rbruno/git/graalvm-argo/benchmarks/data:/usr/share/nginx/html --name web nginx

if [ ! -f ffmpeg ];
then
    wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
    tar -xf ffmpeg-release-amd64-static.tar.xz
    mv ffmpeg-*-amd64-static/ffmpeg .
    rm -r ffmpeg-*-amd64-static
    rm ffmpeg-release-amd64-static.tar.xz
fi

python -m http.server 8000
