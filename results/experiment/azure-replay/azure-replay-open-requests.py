#!/usr/bin/python

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path


def maybe_plot(series_name, label, **kwargs):
    path = Path(series_name)
    if path.exists():
        plt.plot(np.loadtxt(path), label=label, **kwargs)


def maybe_plot_with_fallback(preferred_name, legacy_name, label, **kwargs):
    preferred_path = Path(preferred_name)
    if preferred_path.exists():
        plt.plot(np.loadtxt(preferred_path), label=label, **kwargs)
        return
    maybe_plot(legacy_name, label, **kwargs)

matplotlib.rcParams.update({'font.size': 16})
plt.rcParams["figure.figsize"] = (10, 4)
maybe_plot("he_open_requests.txt", "Herac", linestyle="-.", linewidth=3)
maybe_plot_with_fallback("hy_dc_open_requests.txt", "gv_dc_open_requests.txt", "Hydra DC", linestyle=":", linewidth=3)
maybe_plot_with_fallback("hy_fork_open_requests.txt", "gv_fork_open_requests.txt", "Hydra Fork", linestyle="-", marker="|", markersize=10, markevery=10, linewidth=3)
maybe_plot("ph_open_requests.txt", "Photons", linestyle="--", linewidth=3)
maybe_plot_with_fallback("hy_snap_open_requests.txt", "gv_snap_open_requests.txt", "Hydra Snapshot", linestyle="-", linewidth=3)
maybe_plot("cr_open_requests.txt", "OpenWhisk", linestyle="-", marker="x", markersize=10, markevery=10, linewidth=3)
plt.xlabel("Time (s)")
plt.ylabel("Open Requests")
plt.grid()
plt.legend(ncol=2, loc='upper right')
plt.tight_layout()
plt.savefig("azure-replay-open-requests.pdf")
plt.savefig("azure-replay-open-requests.png")
plt.show()
