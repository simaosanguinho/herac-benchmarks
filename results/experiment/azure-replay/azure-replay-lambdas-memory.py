#!/usr/bin/python3

import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


RUNTIMES = (
    ("he", None, "Herac", "tab:blue"),
    ("hy", "gv_dc", "Hydra", "tab:orange"),
    ("hy_fork", "gv_fork", "Hydra Fork", "tab:green"),
    ("hy_snap", "gv_snap", "Hydra Snapshot", "tab:purple"),
    ("ow", "cr", "OpenWhisk", "tab:green"),
    ("kn", "knative", "Knative", "tab:red"),
)


def load_series(prefix, legacy_prefix):
    prefixes = (prefix,) if legacy_prefix is None else (prefix, legacy_prefix)
    for candidate in prefixes:
        lambda_path = Path(f"{candidate}_active_lambdas.txt")
        if candidate == "he":
            sandbox_path = Path("he_active_sandboxes.txt")
            if sandbox_path.exists():
                lambda_path = sandbox_path
        footprint_path = Path(f"{candidate}_footprint.txt")
        if lambda_path.exists() and footprint_path.exists():
            lambdas = np.atleast_1d(np.loadtxt(lambda_path))
            footprint_mb = np.atleast_1d(np.loadtxt(footprint_path))
            if len(lambdas) != len(footprint_mb):
                print(
                    f"Skipping {candidate}: {lambda_path.name} has {len(lambdas)} samples, "
                    f"but {footprint_path.name} has {len(footprint_mb)}.",
                    file=sys.stderr,
                )
                return None
            return lambdas, footprint_mb / 1000.0
    return None


def load_open_requests_series(prefix, legacy_prefix):
    prefixes = (prefix,) if legacy_prefix is None else (prefix, legacy_prefix)
    for candidate in prefixes:
        requests_path = Path(f"{candidate}_open_requests.txt")
        footprint_path = Path(f"{candidate}_footprint.txt")
        if requests_path.exists() and footprint_path.exists():
            requests = np.atleast_2d(np.loadtxt(requests_path))
            footprint_mb = np.atleast_1d(np.loadtxt(footprint_path))
            if requests.shape[1] != 2:
                print(
                    f"Skipping {candidate}: {requests_path.name} must contain timestamp and request-count columns.",
                    file=sys.stderr,
                )
                return None
            if len(requests) != len(footprint_mb):
                print(
                    f"Skipping {candidate}: {requests_path.name} has {len(requests)} samples, "
                    f"but {footprint_path.name} has {len(footprint_mb)}.",
                    file=sys.stderr,
                )
                return None
            return requests[:, 1], footprint_mb / 1000.0
    return None


def main():
    plt.rcParams.update({"font.size": 14})
    figure, lambda_axis = plt.subplots(figsize=(10, 4))
    memory_axis = lambda_axis.twinx()
    scatter_figure, scatter_axis = plt.subplots(figsize=(6, 4))
    requests_scatter_figure, requests_scatter_axis = plt.subplots(figsize=(6, 4))

    plotted = False
    requests_plotted = False
    for prefix, legacy_prefix, label, color in RUNTIMES:
        series = load_series(prefix, legacy_prefix)
        if series is not None:
            lambdas, footprint_gb = series
            samples = np.arange(len(lambdas))
            unit = "sandboxes" if prefix == "he" and Path("he_active_sandboxes.txt").exists() else "lambdas"
            lambda_axis.plot(samples, lambdas, color=color, linewidth=2, label=f"{label} {unit}")
            memory_axis.plot(samples, footprint_gb, color=color, linestyle="--", linewidth=2, label=f"{label} host memory")
            scatter_axis.scatter(lambdas, footprint_gb, color=color, alpha=0.7, s=18, label=label)
            plotted = True

        requests_series = load_open_requests_series(prefix, legacy_prefix)
        if requests_series is not None:
            open_requests, footprint_gb = requests_series
            requests_scatter_axis.scatter(open_requests, footprint_gb, color=color, alpha=0.7, s=18, label=label)
            requests_plotted = True

    if not plotted:
        raise SystemExit("No matching active-lambda and footprint series found.")

    lambda_axis.set_xlabel("Time (s)")
    lambda_axis.set_ylabel("Active lambdas / Herac sandboxes")
    memory_axis.set_ylabel("Host memory footprint (GiB)")
    lambda_axis.grid()
    lines = lambda_axis.get_lines() + memory_axis.get_lines()
    lambda_axis.legend(lines, [line.get_label() for line in lines], ncol=2, loc="upper left")
    figure.tight_layout()
    figure.savefig("azure-replay-lambdas-memory-timeline.pdf")
    figure.savefig("azure-replay-lambdas-memory-timeline.png", dpi=300)

    scatter_axis.set_xlabel("Active lambdas")
    scatter_axis.set_ylabel("Host memory footprint (GiB)")
    scatter_axis.grid()
    scatter_axis.legend()
    scatter_figure.tight_layout()
    scatter_figure.savefig("azure-replay-lambdas-memory-scatter.pdf")
    scatter_figure.savefig("azure-replay-lambdas-memory-scatter.png", dpi=300)

    if requests_plotted:
        requests_scatter_axis.set_xlabel("Open requests")
        requests_scatter_axis.set_ylabel("Host memory footprint (GiB)")
        requests_scatter_axis.grid()
        requests_scatter_axis.legend()
        requests_scatter_figure.tight_layout()
        requests_scatter_figure.savefig("azure-replay-open-requests-memory-scatter.pdf")
        requests_scatter_figure.savefig("azure-replay-open-requests-memory-scatter.png", dpi=300)


if __name__ == "__main__":
    main()
