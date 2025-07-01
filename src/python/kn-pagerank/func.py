from parliament import Context
from flask import Request

import datetime
import igraph


def pr(size):
    graph_generating_begin = datetime.datetime.now()
    graph = igraph.Graph.Barabasi(size, 10)
    graph_generating_end = datetime.datetime.now()

    process_begin = datetime.datetime.now()
    result = graph.pagerank()
    process_end = datetime.datetime.now()

    graph_generating_time = (graph_generating_end - graph_generating_begin) / datetime.timedelta(microseconds=1)
    process_time = (process_end - process_begin) / datetime.timedelta(microseconds=1)

    return {
            'result': result[0],
            'measurement': {
                'graph_generating_time': graph_generating_time,
                'compute_time': process_time
            }
    }


def main(context: Context):
    if 'request' in context.keys():
        size = int(context.request.json["size"])

        try:
            return {"result": pr(size)}, 200
        except Exception as e:
            return {"result": str(e)}, 500
    else:
        print("Empty request", flush=True)
        return "{}", 400
