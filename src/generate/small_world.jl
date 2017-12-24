"""
    graph_smallworld(n::Integer, m::Integer, p::Real, multiple=false; params...)

Small-world network model of Watts and Strogatz (1998).

# Arguments
* `n`: number of nodes
* `k`: number of neighbors for each node, should be even
* `p`: probability of random rewiring of an edge
* `multi::Bool=false`: whether or not multiple edges are allowed

# References
Watts, D. J., & Strogatz, S. H. (1998).
Collective dynamics of “small-world” networks. Nature, 393(6684), 440–442.
"""
function graph_smallworld(n::Integer, k::Integer, p::Real, multi::Bool=false; params...)
    @assert(n > 5,         "number of nodes (n) is too small; it should be > 5")
    @assert(0 < k < n / 2, "node number of neighbors (k) is not in a valid range")
    @assert(k % 2 == 0,    "node number of neighbors (k) should be even")
    @assert(0 <= p <= 1,   "rewiring probability (p) is not in [0,1] interval")
    g = Graph(; nodecount=n, params...)
    c = Int(k / 2)
    for i = 1:n
        for j = 1:c
            x = (i + j - 1) % n + 1    # target index in ring lattice
            if p == 0 || rand() >= p
                addedge!(g, i, x)
            else
                while true
                    k = rand(1:n)
                    k != i && (multi || !hasedge(g, i, k)) && break
                end
                addedge!(g, i, k)
            end
        end
    end
    return g
end
