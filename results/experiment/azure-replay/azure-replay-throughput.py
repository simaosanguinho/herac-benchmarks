#!/usr/bin/python

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

def numpy_ewma_vectorized(data, window):

    alpha = 2 /(window + 1.0)
    alpha_rev = 1-alpha

    scale = 1/alpha_rev
    n = data.shape[0]

    r = np.arange(n)
    scale_arr = scale**r
    offset = data[0]*alpha_rev**(r+1)
    pw0 = alpha*alpha_rev**(n-1)

    mult = data*pw0*scale_arr
    cumsums = mult.cumsum()
    out = offset + cumsums*scale_arr[::-1]
    return out


def maybe_plot(series_name, label, **kwargs):
    path = Path(series_name)
    if path.exists():
        plt.plot(numpy_ewma_vectorized(np.loadtxt(path), 10), label=label, **kwargs)


def maybe_plot_with_fallback(preferred_name, legacy_name, label, **kwargs):
    preferred_path = Path(preferred_name)
    if preferred_path.exists():
        plt.plot(numpy_ewma_vectorized(np.loadtxt(preferred_path), 10), label=label, **kwargs)
        return
    maybe_plot(legacy_name, label, **kwargs)

matplotlib.rcParams.update({'font.size': 16})
plt.rcParams["figure.figsize"] = (10, 4)
maybe_plot("he_throughput.txt", "Herac", linestyle="-.", linewidth=3)
maybe_plot_with_fallback("hy_dc_throughput.txt", "gv_dc_throughput.txt", "Hydra DC", linestyle=":", linewidth=3)
maybe_plot_with_fallback("hy_fork_throughput.txt", "gv_fork_throughput.txt", "Hydra Fork", linestyle="-", marker="|", markersize=10, markevery=10, linewidth=3)
maybe_plot("ph_throughput.txt", "Photons", linestyle="--", linewidth=3)
maybe_plot_with_fallback("hy_snap_throughput.txt", "gv_snap_throughput.txt", "Hydra Snapshot", linestyle="-", linewidth=3)
maybe_plot("cr_throughput.txt", "OpenWhisk", linestyle="-", marker="x", markersize=10, markevery=10, linewidth=3)
plt.xlabel("Time (s)")
plt.ylabel("Throughput (ops/s)")
plt.grid()
plt.ylim(ymin=0, ymax=20)
plt.xlim(xmin=0, xmax=1200)
#plt.xlim(xmin=100, xmax=200)
#plt.legend(ncol=4, loc='upper right')
plt.tight_layout()
plt.savefig("azure-replay-throughput.pdf")
plt.savefig("azure-replay-throughput.png")
plt.show()
