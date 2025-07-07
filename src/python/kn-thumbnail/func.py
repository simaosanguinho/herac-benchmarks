from parliament import Context
from flask import Request

import io
import shutil
import urllib.request

import requests
from PIL import Image
import os
import threading


# Global variables.
WIDTH = 100
HEIGHT = 100


def init_sandbox_dir():
    tid = threading.get_ident()
    sandbox_dir = f"/tmp/sandbox-{tid}"
    os.makedirs(sandbox_dir, exist_ok=True)
    return sandbox_dir


# Workload.
def thumbnail(img_url):
    tmp_dir = init_sandbox_dir()
    input_img_filename = "{dir}/input-img.png".format(dir=tmp_dir)

    with urllib.request.urlopen(img_url) as response:
        with open(input_img_filename, 'wb') as tmp_file:
            shutil.copyfileobj(response, tmp_file)

        img_filename = "{dir}/thumbnail-img.png".format(dir=tmp_dir)
        with open(tmp_file.name, 'rb') as encoded_img:
            data = encoded_img.read()
            img = Image.open(io.BytesIO(data))
            img = img.resize((WIDTH, HEIGHT))
            img.save(img_filename, 'png')

        with open(img_filename, 'rb') as img:
            requests.post(img_url, headers={'Content-Type': 'image/jpeg'}, data=img)

#        os.remove(img_filename)
        return img_filename


def main(context: Context):
    if 'request' in context.keys():
        url = context.request.json["url"]

        try:
            return {"result": thumbnail(url)}, 200
        except Exception as e:
            return {"result": str(e)}, 500
    else:
        print("Empty request", flush=True)
        return "{}", 400
