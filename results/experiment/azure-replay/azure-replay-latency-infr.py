#!/usr/bin/python3

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


RUNTIMES = (
    ("kn_infr_latency.txt", "knative_infr_latency.txt", "Knative", {"linestyle": "-", "marker": "o", "markersize": 10, "markevery": 10, "linewidth": 3, "color": "tab:red"}),
    ("ow_infr_latency.txt", "cr_infr_latency.txt", "OpenWhisk", {"linestyle": "-", "marker": "x", "markersize": 10, "markevery": 10, "linewidth": 3, "color": "tab:green"}),
    ("he_infr_latency.txt", None, "Herac", {"linestyle": "-.", "linewidth": 3, "color": "tab:blue"}),
    ("hy_infr_latency.txt", "gv_dc_infr_latency.txt", "Hydra", {"linestyle": ":", "linewidth": 3, "color": "tab:orange"}),
    ("hy_fork_infr_latency.txt", "gv_fork_infr_latency.txt", "Hydra Fork", {"linestyle": "-", "marker": "|", "markersize": 10, "markevery": 10, "linewidth": 3}),
    ("ph_infr_latency.txt", None, "Photons", {"linestyle": "--", "linewidth": 3}),
    ("hy_snap_infr_latency.txt", "gv_snap_infr_latency.txt", "Hydra Snapshot", {"linestyle": "-", "linewidth": 3}),
)


def plot_cdf(series_name, label, **kwargs):
    path = Path(series_name)
    if not path.exists():
        return False

    values = np.atleast_1d(np.loadtxt(path))
    x_values = np.sort(values)
    y_values = (np.arange(len(values)) + 1) / float(len(values))
    plt.plot(x_values, y_values, label=label, **kwargs)
    return True


def main():
    plt.rcParams.update({"font.size": 16, "figure.figsize": (10, 4)})

    plotted = False
    for preferred_name, legacy_name, label, style in RUNTIMES:
        if plot_cdf(preferred_name, label, **style):
            plotted = True
        elif legacy_name is not None and plot_cdf(legacy_name, label, **style):
            plotted = True

    if not plotted:
        raise SystemExit("No infrastructure-latency series found.")

    plt.xscale("log")
    plt.ylim(ymin=0.9, ymax=1)
    plt.xlabel("Infrastructure Latency (ms)")
    plt.ylabel("CDF")
    plt.grid(True, which="major", linestyle="--")
    plt.legend(ncol=2, loc="lower right")
    plt.tight_layout()
    plt.savefig("azure-replay-latency-infr.pdf")
    plt.savefig("azure-replay-latency-infr.png", dpi=300)


if __name__ == "__main__":
    main()
