"""
    path(n::Integer)

Generate a [path graph](https://en.wikipedia.org/wiki/Path_graph) with `n` nodes.
"""
function path(n::Integer; params...)
    g = Graph(; params...)
    addnode!(g, n)
    for i = 1:n-1
        addedge!(g, i, i+1)
    end
    g
end

"""
    cycle(n::Integer)

Generate a [cycle graph](https://en.wikipedia.org/wiki/Cycle_graph) with `n` nodes.
"""
function cycle(n::Integer; params...)
    g = Graph(; params...)
    addnode!(g, n)
    for i = 1:n
        addedge!(g, i, (i+1)%n)
    end
    g
end

"""
    star(n::Integer; [out=true])

Generate a [star graph](https://en.wikipedia.org/wiki/Star_graph) with `n` nodes.
If `out == true`, connections go outwards from the central node.
Otherwise, they go inwards.
"""
function star(n::Integer; out=true, params...)
    g = Graph(; params...)
    addnode!(g, n)
    for i = 2:n
        if out
            addedge!(g, 1, i)   # outwards
        else
            addedge!(g, i, 1)   # inwards
        end
    end
    g
end

"""
    wheel(n::Integer; [out=true])

Generate a [wheel graph](https://en.wikipedia.org/wiki/Wheel_graph) with `n` nodes.
If `out == true`, connections go outwards from the central node.
Otherwise, they go inwards.
"""
function wheel(n::Integer; params...)
    g = Graph(; params...)
    addnode!(g, n)
    for i = 2:n
        out ? addedge!(g, 1, i) : addedge!(g, i, 1)
        addedge!(g, i, i<n ? i+1 : 2)
    end
    g
end

"""
    complete(n::Integer)

Generate a [complete graph](https://en.wikipedia.org/wiki/Complete_graph) with `n` nodes.
"""
function complete(n::Integer; params...)
    g = Graph(; params...)
    addnode!(g, n)
    for i = 1:n, j = i+1:n
        addedge!(g, i, j)
    end
    g
end

function _branch!(g::Graph, root, i, l, d)
    for j = 1:l
        addnode!(g)
        k = nodecount(g)
        addedge!(g, k, root)
        if i < d
            _branch!(g, k, i+1, l, d)
        end
    end
end

"""
    tree(l::Integer, d::Integer)

Builds a regular tree with depth `d` and branching factor `l`.
"""
function tree(l::Integer, d::Integer; params...)
    g = Graph(; params...)
    addnode!(g)
    _branch!(g, 1, 1, l, d)
    g
end
