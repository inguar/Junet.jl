"""
    graph_preferential(n::Integer, m::Integer)

Scale-free network model of Barabási and Albert (1999).

# Arguments
* `n`: number of nodes,
* `m`: number of edges added with each subsequent node.

# References
Barabási, A.-L., & Albert, R. (1999).
Emergence of Scaling in Random Networks. Science, 286(5439), 509.
"""
function graph_preferential(n::Integer, m::Integer; kwargs...)
    g = Graph(n; kwargs...)
    p = DiscreteSampler(Int[])
    for i = 1:m         # initial complete subgraph on `m` nodes
        for j = 1:i - 1
            addedge!(g, i, j)
        end
        push!(p, max(1, m - 1))
    end
    for i = m + 1:n     # preferential attachment for remaining nodes
        while outdegree(g, i) < m
            j = randd(p)
            hasedge(g, i, j) && continue
            addedge!(g, i, j)
            inc_index!(p, j)
        end
        push!(p, m)
    end
    return g
end
