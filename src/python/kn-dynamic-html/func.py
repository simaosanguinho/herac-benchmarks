from parliament import Context
from flask import Request

import requests
from datetime import datetime
from random import sample
import pystache


def dynamic_html(url, username, nsize):
    response = requests.get(url)
    template_args = { 'cur_time': str(datetime.now()), 'username' : username, 'random_numbers': sample(range(0, 1000), int(nsize)) }
    template = response.text
    return pystache.render(template, template_args)


def main(context: Context):
    if 'request' in context.keys():
        url = context.request.json["url"]
        username = context.request.json["username"]
        nsize = context.request.json["nsize"]

        try:
            return {"result": dynamic_html(url, username, nsize)}, 200
        except Exception as e:
            return {"result": str(e)}, 500
    else:
        print("Empty request", flush=True)
        return "{}", 400
