import os
import shutil
import requests

def compression(url, tmp_dir):
    dir_path = tmp_dir + "/pyco-" + os.path.basename(url)
    file_path = os.path.join(dir_path, os.path.basename(url))
    if not os.path.exists(dir_path):
        os.mkdir(dir_path)
    with open(file_path, 'wb') as ofile:
        response = requests.get(url)
        ofile.write(response.content)
    return shutil.make_archive(dir_path, 'zip', dir_path)

def main(args):
    try:
        url, tmp_dir = args.split(";")
        return {"result": compression(url, tmp_dir)}
    except Exception as e:
        return {"result": str(e)}

#print(main("http://194.210.228.197:8000/video.mp4;/tmp"))
