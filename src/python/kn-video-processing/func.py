from parliament import Context
from flask import Request

import os
import stat
import subprocess
import requests
import threading


def init_sandbox_dir():
    tid = threading.get_ident()
    sandbox_dir = f"/tmp/sandbox-{tid}"
    os.makedirs(sandbox_dir, exist_ok=True)
    return sandbox_dir


def call_ffmpeg(ffmpeg_path, args):
    ret = subprocess.run([ffmpeg_path, '-y'] + args,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT
    )

    if ret.returncode != 0:
        print('Invocation of ffmpeg failed!')
        print('Out: ', ret.stdout.decode('utf-8'))
        raise RuntimeError()

def to_gif(ffmpeg_path, video, duration, tmp_dir):
    output = '{dir}/processed-{fname}.gif'.format(dir=tmp_dir, fname=os.path.basename(video))
    call_ffmpeg(ffmpeg_path, ["-i", video,
        "-t",
        "{0}".format(duration),
        "-vf",
        "fps=10,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
        "-loop", "0",
        output])
    return output

def set_ffmpeg_executable(ffmpeg_path):
    try:
        os.chmod(ffmpeg_path, os.stat(ffmpeg_path).st_mode | stat.S_IEXEC)
    except OSError:
        pass

def videoprocessing(ffmpeg_url, video_url, tmp_dir):
    ffmpeg_path = tmp_dir + "/ffmpeg"
    video_path = tmp_dir + "/video.mp4"

    if not os.path.exists(ffmpeg_path):
        with open(ffmpeg_path, 'wb') as ofile:
            response = requests.get(ffmpeg_url)
            ofile.write(response.content)
        set_ffmpeg_executable(ffmpeg_path)

    with open(video_path, 'wb') as ofile:
        response = requests.get(video_url)
        ofile.write(response.content)

    return to_gif(ffmpeg_path, video_path, "1", tmp_dir)


def main(context: Context):
    if 'request' in context.keys():
        ffmpeg = context.request.json["ffmpeg"]
        video = context.request.json["video"]

        try:
            tmp_dir = init_sandbox_dir()
            return {"result": videoprocessing(ffmpeg, video, tmp_dir)}, 200
        except Exception as e:
            return {"result": str(e)}, 500
    else:
        print("Empty request", flush=True)
        return "{}", 400
