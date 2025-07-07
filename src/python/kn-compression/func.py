from parliament import Context
from flask import Request
import os
import shutil
import requests
import threading


def init_sandbox_dir():
    tid = threading.get_ident()
    sandbox_dir = f"/tmp/sandbox-{tid}"
    os.makedirs(sandbox_dir, exist_ok=True)
    return sandbox_dir


def compression(url):
    tmp_dir = init_sandbox_dir()

    dir_path = tmp_dir + "/pyco-" + os.path.basename(url)
    file_path = os.path.join(dir_path, os.path.basename(url))
    if not os.path.exists(dir_path):
        os.mkdir(dir_path)
    with open(file_path, 'wb') as ofile:
        response = requests.get(url)
        ofile.write(response.content)
    return shutil.make_archive(dir_path, 'zip', dir_path)


def main(context: Context):
    if 'request' in context.keys():
        url = context.request.json["url"]
        try:
            return {"result": compression(url)}, 200
        except Exception as e:
            return {"result": str(e)}, 500
    else:
        print("Empty request", flush=True)
        return "{}", 400
