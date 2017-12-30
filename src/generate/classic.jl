## Generators for some "classic" graphs ##

"""
    graph_path(n::Integer)

Generate a [path graph](https://en.wikipedia.org/wiki/Path_graph) with `n` nodes.

# Examples
```julia-repl
julia> graph_path(10)
10-node 9-edge directed multigraph
```
"""
function graph_path(n::Integer; params...)
    g = Graph(; nodecount=n, params...)
    for i = 1:n - 1
        addedge!(g, i, i + 1)
    end
    return g
end

"""
    graph_cycle(n::Integer)

Generate a [cycle graph](https://en.wikipedia.org/wiki/Cycle_graph) with `n` nodes.

# Examples
```julia-repl
julia> graph_cycle(10)
10-node 10-edge directed multigraph
```
"""
function graph_cycle(n::Integer; params...)
    g = Graph(; nodecount=n, params...)
    for i = 1:n
        addedge!(g, i, i % n + 1)
    end
    return g
end

"""
    graph_star(n::Integer[; out=true])

Generate a [star graph](https://en.wikipedia.org/wiki/Star_graph) with `n` nodes.
If `out == true`, connections go outwards from the central node.
Otherwise, they go inwards.

# Examples
```julia-repl
julia> graph_star(10)
10-node 9-edge directed multigraph
```
"""
function graph_star(n::Integer; out::Bool=true, params...)
    g = Graph(; nodecount=n, params...)
    for i = 2:n
        if out
            addedge!(g, 1, i)   # outwards
        else
            addedge!(g, i, 1)   # inwards
        end
    end
    return g
end

"""
    graph_wheel(n::Integer[; out=true])

Generate a [wheel graph](https://en.wikipedia.org/wiki/Wheel_graph) with `n` nodes.
If `out == true`, connections go outwards from the central node.
Otherwise, they go inwards.

# Examples
```julia-repl 
julia> graph_wheel(10)
10-node 18-edge directed multigraph
```
"""
function graph_wheel(n::Integer; out::Bool=true, params...)
    g = Graph(; nodecount=n, params...)
    for i = 2:n
        out ? addedge!(g, 1, i) : addedge!(g, i, 1)
        addedge!(g, i, i < n ? i + 1 : 2)
    end
    return g
end

"""
    graph_complete(n::Integer[; ordered=false])

Generate a [complete graph](https://en.wikipedia.org/wiki/Complete_graph) with `n` nodes.

If you are generating a directed graph, by default it will have 2 edges between
each pair of nodes. To leave only edges `i → j` where `i < j`, set `ordered=true`.

# Examples
```julia-repl
julia> graph_complete(10)
10-node 90-edge directed multigraph

julia> graph_complete(10, ordered=true)
10-node 45-edge directed multigraph
```
"""
function graph_complete(n::Integer; ordered::Bool=false, params...)
    g = Graph(; nodecount=n, params...)
    if isdirected(g) && !ordered
        for i = 1:n, j = 1:n
            i != j && addedge!(g, i, j)
        end
    else
        for i = 1:n, j = i + 1:n
            addedge!(g, i, j)
        end
    end
    return g
end

"""
    graph_grid(a::Integer[, b=a])

Generate a rectangular grid of size `a`×`b`.
If `b` is ommitted, it is taken to be equal `a`.

# Examples
```julia-repl
julia> graph_grid(10, 5)
50-node 85-edge directed multigraph
```
"""
function graph_grid(a::Integer, b::Integer=a; params...)
    g = Graph(; nodecount=a * b, params...)
    for i = 1:a, j = 1:b
        cur = (i - 1) * b + j
        if i < a
            addedge!(g, cur, cur + b)
        end
        if j < b
            addedge!(g, cur, cur + 1)
        end
    end
    return g
end

"""
    graph_web(c::Integer, r::Integer[; out=true])

Generate a spiderweb-shaped graph with `c` nodes on each of `r` levels.
Overall, it has `c * r + 1` nodes including the center node.

# Examples
```julia-repl
julia> graph_web(20, 4)
81-node 160-edge directed multigraph
```
"""
function graph_web(c::Integer, r::Integer; out=true, params...)
    g = Graph(; nodecount=r * c + 1, params...)
    for i = 1:r, j = 1:c
        cur = 1 + (i - 1) * c + j
        if out                                              # radial
            addedge!(g, i == 1 ? 1 : cur - c, cur)
        else
            addedge!(g, cur, i == 1 ? 1 : cur - c)
        end
        addedge!(g, cur, j < c ? cur + 1 : cur - c + 1)     # lateral
    end
    return g
end

function branch!(g::Graph, root, depth, c, out)
    for j = 1:c
        k = addnode!(g)
        out ? addedge!(g, root, k) : addedge!(g, k, root)
        if depth > 0
            branch!(g, k, depth - 1, c, out)
        end
    end
end

"""
    graph_tree(c::Integer, r::Integer)

Generate a tree with branching factor `c` and `r` levels.
Mind that it has exponential number of nodes in `r`,
so it is not advisable to create graphs with `r > 4`.

# Examples
```julia-repl
julia> graph_tree(3, 3)
40-node 39-edge directed multigraph
```
"""
function graph_tree(c::Integer, r::Integer; out=true, params...)
    g = Graph(; params...)
    addnode!(g)
    branch!(g, 1, r - 1, c, out)
    return g
end
