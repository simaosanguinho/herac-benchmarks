from parliament import Context
from flask import Request

import io
import shutil
import tempfile
import time
import urllib.request

import requests
from PIL import Image

# Global variables.
WIDTH = 100
HEIGHT = 100

# Util methods.
def current_milli_time():
    return round(time.time() * 1000)


# Workload.
def thumbnail(img_url):
    with urllib.request.urlopen(img_url) as response:
        with tempfile.NamedTemporaryFile(delete=False) as tmp_file:
            shutil.copyfileobj(response, tmp_file)

        img_filename = "img-{}.png".format(current_milli_time())
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
