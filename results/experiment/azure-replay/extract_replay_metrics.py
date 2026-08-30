#!/usr/bin/python3

import argparse
import json
import re
from pathlib import Path


LATENCY_RE = re.compile(r"req:\s*(\d+);\s*infr:\s*(\d+)\s*\[us\]")


def parse_args():
    parser = argparse.ArgumentParser(description="Extract normalized replay metrics for plotting.")
    parser.add_argument("--metrics", required=True, help="Path to Lambda Manager manager_metrics/metrics.log")
    parser.add_argument("--manager-log", required=True, help="Path to Lambda Manager manager_logs/lambda_manager.log")
    parser.add_argument("--prefix", required=True, help="Runtime prefix, e.g. he, gv_dc, cr, kn")
    parser.add_argument("--out-dir", required=True, help="Output directory for normalized series files")
    return parser.parse_args()


def load_metrics(path):
    with open(path, "r", encoding="utf-8") as handle:
        content = handle.read()

    try:
        return json.loads(content)
    except json.JSONDecodeError:
        pass

    metrics = []
    for raw_line in content.splitlines():
        line = raw_line.strip()
        if not line or line in {"[", "]"}:
            continue
        if line.endswith(","):
            line = line[:-1]
        try:
            metrics.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return metrics


def write_series(out_dir, prefix, metric_name, values):
    output_path = out_dir / f"{prefix}_{metric_name}.txt"
    with open(output_path, "w", encoding="utf-8") as handle:
        for value in values:
            handle.write(f"{value}\n")


def write_timestamped_series(out_dir, prefix, metric_name, timestamps_ms, values):
    output_path = out_dir / f"{prefix}_{metric_name}.txt"
    with open(output_path, "w", encoding="utf-8") as handle:
        for timestamp_ms, value in zip(timestamps_ms, values):
            handle.write(f"{timestamp_ms / 1000.0} {value}\n")


def extract_latencies_ms(path):
    latencies = []
    with open(path, "r", encoding="utf-8") as handle:
        for line in handle:
            match = LATENCY_RE.search(line)
            if match is None:
                continue
            request_us = int(match.group(1))
            latencies.append(request_us / 1000.0)
    return latencies


def main():
    args = parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    metrics = load_metrics(args.metrics)

    write_series(out_dir, args.prefix, "active_lambdas", [entry["active_lambdas"] for entry in metrics])
    write_series(out_dir, args.prefix, "active_users", [entry["active_users"] for entry in metrics])
    write_timestamped_series(
        out_dir,
        args.prefix,
        "open_requests",
        [entry["timestamp"] for entry in metrics],
        [entry["open_requests"] for entry in metrics],
    )
    write_series(out_dir, args.prefix, "footprint", [entry["system_footprint"] for entry in metrics])
    write_series(out_dir, args.prefix, "throughput", [entry["throughput"] for entry in metrics])

    latencies_ms = extract_latencies_ms(args.manager_log)
    write_series(out_dir, args.prefix, "avg_latency", latencies_ms)


if __name__ == "__main__":
    main()
