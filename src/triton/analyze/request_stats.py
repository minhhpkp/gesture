import json

with open("trace.json") as f:
    traces = json.load(f)

traces_concat = {}
for trace in traces:
    if trace["id"] not in traces_concat:
        traces_concat[trace["id"]] = {}
        traces_concat[trace["id"]]["timestamps"] = {}
    if "timestamps" in trace:
        traces_concat[trace["id"]]["timestamps"].update({ts["name"]: ts["ns"] for ts in trace["timestamps"]})
    else:
        traces_concat[trace["id"]].update(trace)

for id, trace in traces_concat.items():
    ts = trace["timestamps"]
    queue_us      = (ts["COMPUTE_START"]        - ts["QUEUE_START"])         / 1000
    compute_in_us = (ts["COMPUTE_INPUT_END"]    - ts["COMPUTE_START"])       / 1000
    compute_us    = (ts["COMPUTE_OUTPUT_START"] - ts["COMPUTE_INPUT_END"])   / 1000
    compute_out_us= (ts["COMPUTE_END"]          - ts["COMPUTE_OUTPUT_START"])/ 1000
    total_us      = (ts["GRPC_SEND_END"]        - ts["REQUEST_START"])     / 1000

    print(f"Request {id}:")
    print(f"model name: {trace["model_name"]} model version: {trace["model_version"]}")
    print(f"  Queue:          {queue_us:.1f} us")
    print(f"  Compute input:  {compute_in_us:.1f} us")
    print(f"  Compute:        {compute_us:.1f} us")
    print(f"  Compute output: {compute_out_us:.1f} us")
    print(f"  Total (server): {total_us:.1f} us")