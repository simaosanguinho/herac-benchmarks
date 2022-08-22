import hashlib
import shutil
import tempfile
import urllib.request

# Global variables.
BUF_SIZE = 65536  # Read stuff in 64kb chunks.


# Workload.
def file_hash(file_url):
    with urllib.request.urlopen(file_url) as response:
        with tempfile.NamedTemporaryFile(delete=False) as tmp_file:
            shutil.copyfileobj(response, tmp_file)

        md5 = hashlib.md5()
        sha1 = hashlib.sha1()
        with open(tmp_file.name, 'rb') as f:
            while True:
                data = f.read(BUF_SIZE)
                if not data:
                    break
                md5.update(data)
                sha1.update(data)

        return md5.hexdigest(), sha1.hexdigest()


# Main function.
def main(args):
    output = {}
    md5, sha1 = file_hash(args['file_url'])
    output['md5'], output['sha1'] = md5, sha1
    return output
