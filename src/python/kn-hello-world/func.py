from parliament import Context
from flask import Request
import json

def main(context: Context):
    return { "result": "Hello world from py!" }, 200
