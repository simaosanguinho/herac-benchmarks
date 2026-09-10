#!/usr,bin/python

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
    y_values = (np.arange(len(values))+1) / float(len(values))
    plt.plot(x_values, y_values, label=label, **kwargs)


def maybe_plot_cdf_with_fallback(preferred_name, legacy_name, label, **kwargs):
    preferred_path = Path(preferred_name)
    if preferred_path.exists():
        maybe_plot_cdf(preferred_name, label, **kwargs)
        return
    maybe_plot_cdf(legacy_name, label, **kwargs)
RUNTIMES = (
    ("he", None, "Herac", "tab:blue"),
    ("hy", "gv_dc", "Hydra", "tab:orange"),
    ("hy_fork", "gv_fork", "Hydra Fork", "tab:green"),
    ("hy_snap", "gv_snap", "Hydra Snapshot", "tab:purple"),
    ("ow", "cr", "OpenWhisk", "tab:green"),
    ("kn", "knative", "Knative", "tab:red"),
)

matplotlib.rcParams.update({'font.size': 16})
plt.rcParams["figure.figsize"] = (10, 4)
maybe_plot_cdf_with_fallback("kn_avg_latency.txt", "knative_avg_latency.txt", "Knative", linestyle="-", marker="o", markersize=10, markevery=10, linewidth=3, color="tab:red")
maybe_plot_cdf_with_fallback("ow_avg_latency.txt", "cr_avg_latency.txt", "OpenWhisk", linestyle="-", marker="x", markersize=10, markevery=10, linewidth=3, color="tab:green")

maybe_plot_cdf("he_avg_latency.txt", "Herac", linestyle="-.", linewidth=3, color="tab:blue")
maybe_plot_cdf_with_fallback("hy_avg_latency.txt", "gv_dc_avg_latency.txt", "Hydra", linestyle=":", linewidth=3, color="tab:orange")
maybe_plot_cdf_with_fallback("hy_fork_avg_latency.txt", "gv_fork_avg_latency.txt", "Hydra Fork", linestyle="-", marker="|", markersize=10, markevery=10, linewidth=3)
maybe_plot_cdf("ph_avg_latency.txt", "Photons", linestyle="--", linewidth=3)
maybe_plot_cdf_with_fallback("hy_snap_avg_latency.txt", "gv_snap_avg_latency.txt", "Hydra Snapshot", linestyle="-", linewidth=3)

# Set x-axis to a logarithmic scale (powers of 10)
plt.xscale("log")
plt.ylim(ymin=0.9, ymax=1)
# only show the 0.9 0.95 and 1 lines on the y-axis
plt.yticks([0.9, 0.95, 1.0])
# Log scale cannot start at 0, set xmin to 1
plt.xlim(xmin=1, xmax=80000)

plt.xlabel("User Request Latency (ms)")
plt.ylabel("CDF")
# Enable grid only for major ticks (10^x)
plt.grid(True, which="major", ls="--")
plt.legend(ncol=2, loc='lower right')
plt.tight_layout()
plt.savefig("azure-replay-latency-avg.pdf")
plt.savefig("azure-replay-latency-avg.png")
plt.show()