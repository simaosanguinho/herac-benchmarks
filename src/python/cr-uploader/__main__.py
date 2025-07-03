import urllib.request
import requests

def uploader(url):
    res = len(requests.get(url).content)
    with urllib.request.urlopen(url) as response:
        requests.post(url, headers={'Content-Type': 'image/png'}, data=response.read())
    return res

def main(args):
    try:
        return { "result": uploader(args['url']) }
    except Exception as e:
        return {"result": str(e)}

# For local testing.
#print(main({"url": "http://localhost:8000/snap.png"}))
