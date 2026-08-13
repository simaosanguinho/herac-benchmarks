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
maybe_plot("he_active_lambdas.txt", "Herac", linestyle="-.", linewidth=3)
maybe_plot_with_fallback("hy_dc_active_lambdas.txt", "gv_dc_active_lambdas.txt", "Hydra DC", linestyle=":", linewidth=3)
maybe_plot_with_fallback("hy_fork_active_lambdas.txt", "gv_fork_active_lambdas.txt", "Hydra Fork", linestyle="-", marker="|", markersize=10, markevery=10, linewidth=3)
maybe_plot("ph_active_lambdas.txt", "Photons", linestyle="--", linewidth=3)
maybe_plot_with_fallback("hy_snap_active_lambdas.txt", "gv_snap_active_lambdas.txt", "Hydra Snapshot", linestyle="-", linewidth=3)
maybe_plot("cr_active_lambdas.txt", "OpenWhisk", linestyle="-", marker="x", markersize=10, markevery=10, linewidth=3)
plt.xlabel("Time (s)")
plt.ylabel("Active microVMs")
plt.grid()
plt.xlim(xmin=0, xmax=1200)
#plt.legend(ncol=2, loc='lower right')
plt.tight_layout()
plt.savefig("azure-replay-active-lambdas.pdf")
plt.savefig("azure-replay-active-lambdas.png")
plt.show()
