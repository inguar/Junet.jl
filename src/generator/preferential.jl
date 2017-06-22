"""
    preferential(n::Integer, m::Integer)

Scale-free network model of Barabási and Albert (1999).

# Arguments
* `n`: number of nodes
* `m`: number of edges added with each subsequent node

# References
Barabási, A.-L., & Albert, R. (1999).
Emergence of Scaling in Random Networks. Science, 286(5439), 509.
"""
function graph_preferential(n::Integer, m::Integer, multi::Bool=false; params...)
    g = Graph(; params...)
    p = DistributionPicker{Int}([])
    for i = 1:m
        addnode!(g)
        push!(p, 1)
    end
    for i = m+1:n
        addnode!(g)
        push!(p, 1)
        for j = 1:m
            k = rand(p)
            if k == i || !multi && hasedge(g, i, k)
                k = rand(p)
            end
            addedge!(g, i, k)
            inc_index!(p, i)
            inc_index!(p, k)
        end
    end
    return g
end
