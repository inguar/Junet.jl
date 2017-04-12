# Code for finding connected components.

@inline function _root(parent, i)
    while i != parent[i]
        i = parent[i] = parent[parent[i]]
    end
    return i
end

"""
    components(g::Graph)

Enumerate all connected components. Returns `Vector` with component affiliations
of nodes. The number of each component is also an index of one of the nodes
that is included in it.

Implementation based on WQUPC algorithm from Robert Sedgewick's lecture
on Union-Find algorithms
[link](https://www.cs.princeton.edu/~rs/AlgsDS07/01UnionFind.pdf).
"""
function components{N,E}(g::Graph{N,E})
    n      = nodecount(g)
    parent = collect(1:n)
    weight = fill(1, n)
    @inbounds for i = 1:n, j = outneighbors(g, i)
        src = _root(parent, i)          # union all
        tgt = _root(parent, Int(j))
        src == tgt && continue
        if weight[src] < weight[tgt]
            parent[src] = tgt
            weight[tgt] += weight[src]
            weight[src] = 0
        else
            parent[tgt] = src
            weight[src] += weight[tgt]
            weight[tgt] = 0
        end
    end
    for i = 1:n                         # find and root all
        while weight[parent[i]] == 0
            parent[i] = parent[parent[i]]
        end
    end
    return parent
end
