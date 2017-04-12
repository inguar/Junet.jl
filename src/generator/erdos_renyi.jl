# Random graph generators.

"""
    randfill!(g, dens)

Fill the graph with random edges until it reaches a certain density.
"""
function randfill!(g::Graph, dens::Real)
    @assert(nodecount(g) > 1, "Too little nodes to add edges")
    @assert(dens < .7, "Too high density value")
    n = round(Int, maxedgecount(g) * dens)
    for i = 1:n
        x = randnode(g)
        y = randnode(g)
        while x == y
            y = randnode(g)
        end
        addedge!(g, x, y)
    end
end


# Sample from a geometric distribution (adapted from the Distributions package)
randgeom(p::Real) = floor(Int, -randexp() / log1p(-p))

function _erdosrenyifill!(g::UndirectedGraph, p::Real)
    i, j = 1, 0
    n = nodecount(g)
    while true
        j += 1 + randgeom(p)
        while j > n
            i += 1
            i > n && return
            j = j - n + i
        end
        addedge!(g, i, j)
    end
end

function _erdosrenyifill!(g::DirectedGraph, p::Real)
    i, j = 1, 0
    n = nodecount(g)
    while true
        j_ = j + 1 + randgeom(p)
        j = (j < i && j_ >= i) ? j_ + 1 : j_
        while j > n
            i += 1
            i > n && return
            j -= n
            j += j >= i
        end
        addedge!(g, i, j)
    end
end

"""
    erdosrenyifill!(g::Graph, p::Real)

Generate an Erdős–Rényi random graph.

When specifying the probability, a series of Bernoulli trials will be simulated
for each possible edge in the graph and they will be created with probability `p`.
Note that in this case the number of edges is different each time, but the
matiematical expectation for the graph's density is `p`.

If you want an exact number of edges, provide it as an argument `m`. In this case
they will be randomly picked from all possible edges in the graph with equal
probability.t
"""
function erdosrenyifill!(g::Graph, p::Real)
    @assert(nodecount(g) > 1, "too little nodes in the graph")
    @assert(0 < p < 1, "value of `p` should be in (0,1) interval")
    _erdosrenyifill!(g, p)
    return g
end

function erdosrenyi(n::Integer, p::Real)
    g = Graph(nodecount=n)
    erdosrenyifill!(g, p)
    return g
end
