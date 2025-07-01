from parliament import Context
from flask import Request
import urllib.request
import requests


def uploader(url):
    res = len(requests.get(url).content)
    with urllib.request.urlopen(url) as response:
        requests.post(url, headers={'Content-Type': 'image/png'}, data=response.read())
    return res


def main(context: Context):
    if 'request' in context.keys():
        url = context.request.json["url"]
        try:
            return {"result": uploader(url)}, 200
        except Exception as e:
            return {"result": str(e)}, 500
    else:
        print("Empty request", flush=True)
        return "{}", 400
