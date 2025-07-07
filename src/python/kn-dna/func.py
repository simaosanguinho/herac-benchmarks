from parliament import Context
from flask import Request

import requests
import datetime
from squiggle import transform
import threading
import os


def init_sandbox_dir():
    tid = threading.get_ident()
    sandbox_dir = f"/tmp/sandbox-{tid}"
    os.makedirs(sandbox_dir, exist_ok=True)
    return sandbox_dir


def dna(fasta_url):
    tmp_dir = init_sandbox_dir()
    fasta_path = tmp_dir + "/bacillus_subtilis.fasta"

    with open(fasta_path, 'wb') as ofile:
        response = requests.get(fasta_url)
        ofile.write(response.content)

    process_begin = datetime.datetime.now()
    result = transform(open(fasta_path, "r").read())
    process_end = datetime.datetime.now()

    return {
            'result': (result[0][:10], result[1][:10]),
            'measurement': {
                'compute_time': (process_end - process_begin) / datetime.timedelta(microseconds=1)
            }
    }


def main(context: Context):
    if 'request' in context.keys():
        fasta_url = context.request.json["fasta_url"]

        try:
            return {"result": transform("ATCTTTTTCGGCTTTTTTTAGTATCCACAGAGGTTATCGACAACATTTTCACATTACCAACCCCTGTGGACAAGGTTTTT")}, 200
        except Exception as e:
            return {"result": str(e)}, 500
    else:
        print("Empty request", flush=True)
        return "{}", 400
