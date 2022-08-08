import urllib.request
from datetime import datetime                                                   
from random import sample 

def dynamic_html(url, username, nsize):
    with urllib.request.urlopen(url) as response:
        template_args = "{ \"cur_time\": \"" + str(datetime.now()) + "\", \"username\" : \"" + username  + "\", \"random_numbers\": " + str(sample(range(0, 1000), int(nsize))) + "}"
        return jsHostAccess.mustache(response.read().decode('utf-8'), template_args)

def main(args):
    try:
        url, username, nsize = args.split(";")
        return {"result": dynamic_html(url, username, nsize)}
    except Exception as e:
        return {"result": str(e)}
