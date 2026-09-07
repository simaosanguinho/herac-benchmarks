import urllib.request
from uuid import uuid4

def uploader(download_url, upload_url):
    with urllib.request.urlopen(download_url) as response:
        content = response.read()

    boundary = uuid4().hex
    separator = f"--{boundary}\r\n".encode()
    closing = f"--{boundary}--\r\n".encode()
    headers = (
        b'Content-Disposition: form-data; name="file"; filename="myimage.png"\r\n'
        b'Content-Type: image/png\r\n\r\n'
    )
    body = separator + headers + content + b"\r\n" + closing

    request = urllib.request.Request(
        upload_url,
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )
    with urllib.request.urlopen(request):
        pass

    return len(content)

def main(args):
    try:
        download_url, upload_url = args.split(";", 1)
        return {"result": uploader(download_url, upload_url)}
    except Exception as e:
        return {"result": str(e)}
