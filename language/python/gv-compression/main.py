import datetime
import os
import stat
import subprocess
import shutil
import tempfile
import urllib.request

def compression(url):
    dir_path = os.path.basename(url)
    file_path = os.path.join(dir_path, os.path.basename(url))
    if not os.path.exists(dir_path):
        os.mkdir(dir_path)
    with urllib.request.urlopen(url) as response, open(file_path, 'wb') as ofile:
        shutil.copyfileobj(response, ofile)
    shutil.make_archive(dir_path, 'zip', dir_path)

def main(args):
    try:
        return {"result": compression(args)}
    except Exception as e:
        return {"result": str(e)}

print(main("http://127.0.0.1:8000/file_example_MP4_480_1_5MG.mp4"))
