## Simple random graph generators ##

"""
    rand_geom(p::Real)
    
Sample a value from geometric distribution with probability of success `p`.
This code is adapted from the [Distributions.jl](https://github.com/JuliaStats/Distributions.jl)
package.
"""
rand_geom(p::Real) = floor(Int, -randexp() / log1p(-p))


function gilbert_fill!(g::UndirectedGraph, p::AbstractFloat)
    i, j = 1, 0
    n = nodecount(g)
    while true
        j += 1 + rand_geom(p)
        while j > n
            i += 1
            i > n && return
            j = j - n + i
        end
        addedge!(g, i, j)
    end
end

function gilbert_fill!(g::DirectedGraph, p::AbstractFloat)
    i, j = 1, 0
    n = nodecount(g)
    while true
        j_ = j + 1 + rand_geom(p)
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
    graph_gilbert(n::Integer, p::AbstractFloat)

Generate a random graph according to Gilbert model with `n` nodes
and expected density `p`.

An independent Bernoulli trial is simulated for each possible edge in the graph
and it is added with probability `p`.
Note that in this case the number of edges is different each time, but the
matiematical expectation for the graph's density is `p`.

# References

Gilbert, E.N. (1959). "Random Graphs". Annals of Mathematical Statistics. 30 (4): 1141–1144.
doi:10.1214/aoms/1177706098.
"""
function graph_gilbert(n::Integer, p::AbstractFloat; params...)
    g = Graph(; nodecount=n, params...)
    gilbert_fill!(g, p)
    return g
end

# TODO: ensure that `p=1` makes `density==1` (somehow fails for undirected)


"""
    graph_erdos_renyi(n::Integer, m::Integer)

Generate an [Erdős–Rényi random graph](https://en.wikipedia.org/wiki/Erdős–Rényi_model)
with `n` nodes and `m` edges.

From mathematical viewpoint, the graph is picked at random with uniform probability
from a set of all possible graphs having `n` nodes and `m` edges. 
In practice, an empty graph with `n` nodes is created first and
`m` edges get added between the randomly chosen pairs of its nodes.

# References

Erdős, P.; Rényi, A. (1959). "On Random Graphs. I". Publicationes Mathematicae. 6: 290–297.
"""
function graph_erdos_renyi(n::Integer, m::Integer; params...)
    @assert(n > 0, "there should be at least one node")
    g = Graph(nodecount=n; params...)
    simple = !ismultigraph(g)
    simple && @assert(m <= maxedgecount(g), "too many edges (m) for a simple graph")
    for i = 1:m
        x = rand(1:n)
        y = rand(1:n)
        while x == y || simple && hasedge(g, x, y)
            x = rand(1:n)
            y = rand(1:n)
        end
        addedge!(g, x, y)
    end
    return g
end

const graph_erdosrenyi = graph_erdos_renyi   # TODO: deprecate this

# TODO: make use of discrete distribution sampler for `graph_erdos_renyi` to avoid slowdown generating high-density graphs


"""
    graph_random(n::Integer, m::Integer)
    graph_random(n::Integer, p::AbstractFloat)

A shorthand for creating random networks. There are two similar but distinct models:

* `(n, m)` model, also known as Erdős–Rényi model. It randomly selects a 
graph from a set of all possible graphs which have `n` nodes and `m` edges.

* `(n, p)` model, introduced by Gilbert. For a graph on `n` nodes,
it includes each edge with probability `p` independently of the others.
This gives a graph with mathematical expectation of density equal to `p`.

This method is just a shorthand for `graph_erdos_renyi` and `graph_gilbert`,
which implement these models and are chosen automatically based on the argument types.

If you want an exact number of edges, use `(n, m)` model.
If you want to create a graph of high density, use `(n, p)` model as it
should be faster.

# References

[Wikipedia](https://en.wikipedia.org/wiki/Erdős–Rényi_model)
"""
graph_random(n::Integer, m::Integer; params...) =
    graph_erdos_renyi(n::Integer, m::Integer; params...)
graph_random(n::Integer, p::AbstractFloat; params...) =
    graph_gilbert(n::Integer, p::AbstractFloat; params...)
