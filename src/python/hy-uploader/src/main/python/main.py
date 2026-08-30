import urllib.request

def uploader(url):
    # Avoid requests/urllib3 here: Hydra's GraalPython image may not provide
    # the ssl module those libraries expect at import time.
    with urllib.request.urlopen(url) as response:
        content = response.read()

    request = urllib.request.Request(
        url,
        data=content,
        headers={"Content-Type": "image/png"},
        method="POST",
    )
    with urllib.request.urlopen(request):
        pass

    return len(content)

def main(url):
    try:
        return {"result": uploader(url)}
    except Exception as e:
        return {"result": str(e)}
