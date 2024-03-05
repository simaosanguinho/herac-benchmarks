import numpy as np

def pagerank(M, d: float = 0.85):
    """PageRank algorithm with explicit number of iterations. Returns ranking of nodes (pages) in the adjacency matrix.

    Parameters
    ----------
    M : numpy array
        adjacency matrix where M_i,j represents the link from 'j' to 'i', such that for all 'j'
        sum(i, M_i,j) = 1
    d : float, optional
        damping factor, by default 0.85

    Returns
    -------
    numpy array
        a vector of ranks such that v_i is the i-th rank from [0, 1],

    """
    N = M.shape[1]
    w = np.ones(N) / N
    M_hat = d * M
    v = M_hat @ w + (1 - d)
    while(np.linalg.norm(w - v) >= 1e-10):
        w = v
        v = M_hat @ w + (1 - d)
    return v

def main(args):
    M = np.array([[0, 0, 0, 0],
                  [0, 0, 0, 0],
                  [1, 0.5, 0, 0],
                  [0, 0.5, 1, 0]])
    return { 'result' : pagerank(M, 0.85) }

#print(main({}))
