"""
    graph_preferential(n::Integer, m::Integer)

Scale-free network model of Barabási and Albert (1999).

# Arguments
* `n`: number of nodes
* `m`: number of edges added with each subsequent node

# References
Barabási, A.-L., & Albert, R. (1999).
Emergence of Scaling in Random Networks. Science, 286(5439), 509.
"""
function graph_preferential(n::Integer, m::Integer, multi::Bool=false; kwargs...)
    g = Graph(; kwargs...)
    p = DiscreteSampler(Int[])
    for i = 1:m
        addnode!(g)
        push!(p, 1)
    end
    for i = m + 1:n
        addnode!(g)
        push!(p, 1)
        for j = 1:m
            k = randd(p)
            if k == i || !multi && hasedge(g, i, k)
                k = randd(p)
            end
            addedge!(g, i, k)
            inc_index!(p, i)
            inc_index!(p, k)
        end
    end
    return g
end

# FIXME: make sure the procedure doesn't generate self-loops
# FIXME: allow to use list of self-loops for bulk edge deletion