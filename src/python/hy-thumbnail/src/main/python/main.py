import io
import shutil
import urllib.request

#import requests
from PIL import Image

# Global variables.
WIDTH = 100
HEIGHT = 100


# Workload.
def thumbnail(img_url, tmp_dir):
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

#        with open(img_filename, 'rb') as img:
#            requests.post(img_url, headers={'Content-Type': 'image/jpeg'}, data=img)

#        os.remove(img_filename)
        return img_filename


def main(args):
    try:
        url, tmp_dir = args.split(";")
        return {"result": thumbnail(url, tmp_dir)}
    except Exception as e:
        return {"result": str(e)}
