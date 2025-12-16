import urllib.request
import requests

def uploader(url):
    res = len(requests.get(url).content)
    with urllib.request.urlopen(url) as response:
        requests.post(url, headers={'Content-Type': 'image/png'}, data=response.read())
    return res

def main(url):
    try:
        return {"result": uploader(url)}
    except Exception as e:
        return {"result": str(e)}
