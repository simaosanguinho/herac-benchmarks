import io
import os
import shutil
import tempfile
import urllib.request

import requests
from PIL import Image

# Global variables.
WIDTH = 100
HEIGHT = 100

# Workload.
def thumbnail(img_url):
    input_img_filename = "/tmp/input-img.png"
    with urllib.request.urlopen(img_url) as response:
        with open(input_img_filename, 'wb') as tmp_file:
            shutil.copyfileobj(response, tmp_file)

        img_filename = "/tmp/thumbnail-img.png"
        with open(tmp_file.name, 'rb') as encoded_img:
            data = encoded_img.read()
            img = Image.open(io.BytesIO(data))
            img = img.resize((WIDTH, HEIGHT))
            img.save(img_filename, 'png')

        with open(img_filename, 'rb') as img:
            requests.post(img_url, headers={'Content-Type': 'image/jpeg'}, data=img)

#        os.remove(img_filename)
        return img_filename


def main(args):
    try:
        return {"result": thumbnail(args['url'])}
    except Exception as e:
        return {"result": str(e)}

# For local testing.
#print(main({"url": "http://localhost:8000/snap.png"}))
