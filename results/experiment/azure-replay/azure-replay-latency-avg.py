#!/usr/bin/python

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path


def maybe_plot_cdf(series_name, label, **kwargs):
    path = Path(series_name)
    if not path.exists():
        return
    values = np.loadtxt(path)
    if np.isscalar(values):
        values = np.asarray([values])
    x_values = np.sort(values)
    y_values = np.arange(len(values)) / float(len(values))
    plt.plot(x_values, y_values, label=label, **kwargs)


def maybe_plot_cdf_with_fallback(preferred_name, legacy_name, label, **kwargs):
    preferred_path = Path(preferred_name)
    if preferred_path.exists():
        maybe_plot_cdf(preferred_name, label, **kwargs)
        return
    maybe_plot_cdf(legacy_name, label, **kwargs)

matplotlib.rcParams.update({'font.size': 16})
plt.rcParams["figure.figsize"] = (10, 4)
maybe_plot_cdf("he_avg_latency.txt", "Herac", linestyle="-.", linewidth=3)
maybe_plot_cdf_with_fallback("hy_dc_avg_latency.txt", "gv_dc_avg_latency.txt", "Hydra DC", linestyle=":", linewidth=3)
maybe_plot_cdf_with_fallback("hy_fork_avg_latency.txt", "gv_fork_avg_latency.txt", "Hydra Fork", linestyle="-", marker="|", markersize=10, markevery=10, linewidth=3)
maybe_plot_cdf("ph_avg_latency.txt", "Photons", linestyle="--", linewidth=3)
maybe_plot_cdf_with_fallback("hy_snap_avg_latency.txt", "gv_snap_avg_latency.txt", "Hydra Snapshot", linestyle="-", linewidth=3)
maybe_plot_cdf("cr_avg_latency.txt", "OpenWhisk", linestyle="-", marker="x", markersize=10, markevery=10, linewidth=3)
plt.ylim(ymin=0, ymax=1)
plt.xlim(xmin=0, xmax=80000)
plt.xlabel("User Request Latency (ms)")
plt.ylabel("CDF")
plt.grid()
plt.legend(ncol=2, loc='lower right')
plt.tight_layout()
plt.savefig("azure-replay-latency-avg.pdf")
plt.savefig("azure-replay-latency-avg.png")
plt.show()
