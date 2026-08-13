#!/usr/bin/python

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path


def maybe_plot(series_name, label, scale=1.0, **kwargs):
    path = Path(series_name)
    if path.exists():
        plt.plot(np.loadtxt(path) / scale, label=label, **kwargs)


def maybe_plot_with_fallback(preferred_name, legacy_name, label, scale=1.0, **kwargs):
    preferred_path = Path(preferred_name)
    if preferred_path.exists():
        plt.plot(np.loadtxt(preferred_path) / scale, label=label, **kwargs)
        return
    maybe_plot(legacy_name, label, scale=scale, **kwargs)

matplotlib.rcParams.update({'font.size': 16})
plt.rcParams["figure.figsize"] = (10, 4)
maybe_plot("he_footprint.txt", "Herac", scale=1000, linestyle="-.", linewidth=3)
maybe_plot_with_fallback("hy_dc_footprint.txt", "gv_dc_footprint.txt", "Hydra DC", scale=1000, linestyle=":", linewidth=3)
maybe_plot_with_fallback("hy_fork_footprint.txt", "gv_fork_footprint.txt", "Hydra Fork", scale=1000, linestyle="-", marker="|", markersize=10, markevery=10, linewidth=3)
maybe_plot("ph_footprint.txt", "Photons", scale=1000, linestyle="--", linewidth=3)
maybe_plot_with_fallback("hy_snap_footprint.txt", "gv_snap_footprint.txt", "Hydra Snapshot", scale=1000, linestyle="-", linewidth=3)
maybe_plot("cr_footprint.txt", "OpenWhisk", scale=1000, linestyle="-", marker="x", markersize=10, markevery=10, linewidth=3)
plt.xlabel("Time (s)")
plt.ylabel("Memory (GBs)")
plt.grid()
plt.xlim(xmin=0, xmax=1200)
#plt.legend(ncol=2, loc='lower right')
plt.tight_layout()
plt.savefig("azure-replay-memory.pdf")
plt.savefig("azure-replay-memory.png", dpi=300)
plt.show()
