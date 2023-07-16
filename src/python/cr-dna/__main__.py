import datetime, io, json
# using https://squiggle.readthedocs.io/en/latest/
from squiggle import transform

def dna(event):

    # TODO - fetch from storage
    data = open("/home/rbruno/git/graalserverless/benchmarks/data/bacillus_subtilis.fasta", "r").read()

    process_begin = datetime.datetime.now()
    result = transform(data)
    process_end = datetime.datetime.now()

    process_time = (process_end - process_begin) / datetime.timedelta(microseconds=1)

    return {
            'result': (result[0][:10], result[1][:10]),
            'measurement': {
                'compute_time': process_time
            }
    }

def main(args):
    try:
        return {"result": dna({})}
    except Exception as e:
        return {"result": str(e)}

print(main({}))
