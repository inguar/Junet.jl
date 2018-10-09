"""
    graph_small_world(n::Integer, m::Integer, p::Real)

Small-world network model of Watts and Strogatz (1998).

# Arguments
* `n` — number of nodes,
* `k` — number of neighbors for each node, should be even,
* `p` — probability of random rewiring of each edge.

# References
Watts, D. J., & Strogatz, S. H. (1998).
Collective dynamics of “small-world” networks. Nature, 393(6684), 440–442.
"""
function graph_small_world(n::Integer, k::Integer, p::Real; kwargs...)
    @assert(n > 5,         "number of nodes (n) should be > 5")
    @assert(0 < k < n / 2, "number of neighbors (k) is not in a valid range")
    @assert(k % 2 == 0,    "number of neighbors (k) should be even")
    @assert(0 < p < 1,     "rewiring probability (p) is not in (0, 1) interval")
    g = Graph(n; kwargs...)
    for i = 1:n, offset = 1:Int(k / 2)
        j = (i + offset - 1) % n + 1
        if rand() < p || hasedge(g, i, j)
            while true
                j = rand(1:n)
                if j != i && !hasedge(g, i, j)
                    break
                end
            end
        end
        addedge!(g, i, j)
    end
    return g
end

@deprecate(graph_smallworld, graph_small_world)
