## Conversion to and from Matrix objects ##

function Graph(m::Matrix{T}; params...) where {T<:Number}
    n, n_ = size(m)
    @assert(n == n_, "adjacency matrix should be square")
    g = Graph(; n=n, params...)
    for i = 1:n, j = 1:n
        if m[i, j] > zero(T)
            addedge!(g, i, j)
        end
    end
    return g
end

function Matrix(g::Graph)
    n = nodecount(g)
    m = zeros(n, n)
    for i = nodes(g), j = outneighbors(g, i)
        m[i, j] += 1
    end
    return m
end
