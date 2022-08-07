import datetime
import os
import stat
import subprocess
import shutil
import tempfile
import urllib.request
import requests

def call_ffmpeg(args):
    ret = subprocess.run([os.path.join("ffmpeg"), '-y'] + args,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT
    )

    if ret.returncode != 0:
        print('Invocation of ffmpeg failed!')
        print('Out: ', ret.stdout.decode('utf-8'))
        raise RuntimeError()

def to_gif(video, duration):
    output = 'processed-{}.gif'.format(os.path.basename(video))
    call_ffmpeg(["-i", video,
        "-t",
        "{0}".format(duration),
        "-vf",
        "fps=10,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
        "-loop", "0",
        output])
    return output

def set_ffmpeg_executable():
    try:
        os.chmod("ffmpeg", os.stat("ffmpeg").st_mode | stat.S_IEXEC)
    except OSError:
        pass

def videoprocessing(ffmpeg_url, video_url):
    if not os.path.exists("ffmpeg"):
        with urllib.request.urlopen(ffmpeg_url) as response, open("ffmpeg", 'wb') as ofile:
            shutil.copyfileobj(response, ofile)
        set_ffmpeg_executable()

    with urllib.request.urlopen(video_url) as response, open("video.mp4", 'wb') as ofile:
        shutil.copyfileobj(response, ofile)

    return to_gif("video.mp4", "1")

def main(args):
    try:
        ffmpeg_url, video_url = args.split(";")
        return {"result": videoprocessing(ffmpeg_url, video_url)}
    except Exception as e:
        return {"result": str(e)}
