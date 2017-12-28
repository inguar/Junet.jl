## Simple graph manipulations (nodes/edges/attributes) ##

#=
##      Operations with nodes
=#

function _addnode!(g::Graph{N,E}) where {N,E}
    @_inline_meta
    @assert(nodecount(g) < typemax(N), "node ids exhausted type $N")
    push!(g.nodes, Node{N,E}())
    return nodecount(g)
end

"""
    addnode!(g::Graph[; attrs...])

Add one node to the graph. If `g` has node attributes, you can set
their values for the new node through keywords.

# Example

```julia-repl
julia> addnode!(g);
julia> g[:, :color] = "red";
julia> addnode!(g, color="blue");
julia> g[:, :color]
 ...
 "red"
 "blue"
```
"""
function addnode!(g::Graph; attrs...)
    n = _addnode!(g)
    for (k, v) = attrs
        @assert(haskey(g.nodeattrs, k), "node attribute $k not found")
        g.nodeattrs[k, n] = v
    end
    return n
end

"""
    addnodes!(g::Graph, count::Integer[; attrs...])

Add several nodes to the graph. If `g` has node attributes, you can set
their values for the new nodes through keywords.

# Example

```julia-repl
julia> addnodes!(g, 3, color=["red", "green", "blue"]);
julia> g[:, :color]
 ...
 "red"
 "green"
 "blue"
```
"""
function addnodes!(g::Graph, count::Integer)
    @assert(count >= 0, "can't add a negative number of nodes")
    for i = 1:count
        _addnode!(g)
    end
    return nodecount(g) - count + 1:nodecount(g)
end

"""
    remnode!(g::Graph, n::Integer)

Remove node `u` from the graph.
"""
function remnode!(g::Graph{N}, n::Integer) where {N}
    g.edgecount -= ptr_length(g.nodes[n], Both)
    for p = fwd_ptrs(g.nodes[n])        # remove pointers to this node
        delete_ptr!(rev_ptrs(g.nodes[p.node]), N(n), p.id)
    end
    for p = rev_ptrs(g.nodes[n])
        delete_ptr!(fwd_ptrs(g.nodes[p.node]), N(n), p.id)
    end
    m = nodecount(g)                    # if last node, remove it
    if n == m
        deleteat!(g.nodes, n)
        return
    end
    g.nodes[n] = pop!(g.nodes)          # if not, move the last node to its position
    for p = fwd_ptrs(g.nodes[n])
        swap_ptr!(rev_ptrs(g.nodes[p.node]), N(m), p.id, N(n))
    end
    for p = rev_ptrs(g.nodes[n])
        swap_ptr!(fwd_ptrs(g.nodes[p.node]), N(m), p.id, N(n))
    end
end

remnodes!(g::Graph, it) = for i = sort(it, rev=true); remnode!(g, i) end

# FIXME: teach these operations work with attributes nicely



#=
##      Operations with edges
=#

"""
    hasedge(g::Graph, e::Edge)
    hasedge(g::Graph, n::Integer, m::Integer)

Check if graph `g` has an edge between nodes `n` and `m`.
"""
hasedge(g::Graph{N,E,D}, e::Edge{N,E}) where {N,E,D<:Directed} =
    has_ptr(fwd_ptrs(g.nodes[e.source], D), e.target)

hasedge(g::Graph{N,E,D}, e::Edge{N,E}) where {N,E,D<:Undirected} =
    has_ptr(fwd_ptrs(g.nodes[e.source], D), e.target) ||
    has_ptr(rev_ptrs(g.nodes[e.source], D), e.target)

hasedge(g::Graph{N,E,D}, n::Integer, m::Integer) where {N,E,D<:Directed} =
    has_ptr(fwd_ptrs(g.nodes[n], D), N(m))

hasedge(g::Graph{N,E,D}, n::Integer, m::Integer) where {N,E,D<:Undirected} =
    has_ptr(fwd_ptrs(g.nodes[n], D), N(m)) ||
    has_ptr(rev_ptrs(g.nodes[n], D), N(m))

"""
    new_ptr_pair!(g::Graph, n, m)

Create a pair of `NodePtr`s to be used for adding a new edge.
"""
function new_ptr_pair!(g::Graph{N,E}, n::N, m::N) where {N,E<:Integer}
    @_inline_meta
    @assert(g.edgemaxid < typemax(E), "edge ids exhausted type $E")
    g.edgemaxid += one(E)
    return NodePtr(m, g.edgemaxid), NodePtr(n, g.edgemaxid)
end

function new_ptr_pair!(g::Graph{N,E}, n::N, m::N) where {N,E<:Void}
    @_inline_meta
    return NodePtr(m, nothing), NodePtr(n, nothing)
end

function _addedge!(g::MultiGraph{N,E,D}, n::Integer, m::Integer) where {N,E,D}
    fwd, rev = new_ptr_pair!(g, N(n), N(m))
    add_ptr!(fwd_ptrs(g.nodes[n], D), fwd)
    add_ptr!(rev_ptrs(g.nodes[m], D), rev)
    g.edgecount += 1
    return g.edgecount
end

function _addedge!(g::SimpleGraph{N,E,D}, n::Integer, m::Integer) where {N,E,D}
    fwd, rev = new_ptr_pair!(g, N(n), N(m))
    add_one_ptr!(fwd_ptrs(g.nodes[n], D), fwd) &&
    add_one_ptr!(rev_ptrs(g.nodes[m], D), rev) ||
    error("graph already contains edge $n → $m")
    g.edgecount += 1
    return g.edgecount
end

"""
    addedge!{N,E}(g::Graph{N,E}, n::Integer, m::Integer[; attrs...])

Add an edge between nodes `n` and `m` in graph `g`.
If `g` has edge attributes, you can set
their values for the new edge through keywords `attrs...`.

# Example

```julia-repl
julia> addedge!(g, 1, 2, color="red");
julia> g[:, :, :color]
 ...
 "red"
```
"""
function addedge!(g::Graph, n::Integer, m::Integer; attrs...)
    e = _addedge!(g, n, m)
    for (k, v) = attrs
        @assert(haskey(g.edgeattrs, k), "edge attribute $k not found")
        g.edgeattrs[k, e] = v
    end
    return e
end

addedges!(g::Graph, it) = for i = collect(it); addedge!(g, i) end

"""
    remedge!(g::Graph, e::Edge)
    remedge!(g::Graph, u::Integer, v::Integer)

Remove edge `e` from graph `g`.
"""
function remedge!(g::Graph{N,E,D}, e::Edge{N,E}) where {N,E,D<:Directed}
    delete_ptr!(fwd_ptrs(g.nodes[e.source], D), e.target, e.id) &&
    delete_ptr!(rev_ptrs(g.nodes[e.target], D), e.source, e.id) ||
    error("edge $e not found")
    g.edgecount -= 1;
end

function remedge!(g::Graph{N,E,D}, e::Edge{N,E}) where {N,E,D<:Undirected}
    delete_ptr!(fwd_ptrs(g.nodes[e.source], D), e.target, e.id) &&
    delete_ptr!(rev_ptrs(g.nodes[e.target], D), e.source, e.id) ||
    delete_ptr!(fwd_ptrs(g.nodes[e.target], D), e.source, e.id) &&
    delete_ptr!(rev_ptrs(g.nodes[e.source], D), e.target, e.id) ||
    error("edge $e not found")
    g.edgecount -= 1;
end

function remedge!(g::Graph{N,E,D}, n::Integer, m::Integer) where {N,E,D<:Directed}
    delete_ptr!(fwd_ptrs(g.nodes[n], D), N(m)) &&
    delete_ptr!(rev_ptrs(g.nodes[m], D), N(n)) ||
    error("edge $(Edge(n, m, 0, true)) not found")
    g.edgecount -= 1;
end

function remedge!(g::Graph{N,E,D}, n::Integer, m::Integer) where {N,E,D<:Undirected}
    delete_ptr!(fwd_ptrs(g.nodes[n], D), N(m)) &&
    delete_ptr!(rev_ptrs(g.nodes[m], D), N(n)) ||
    delete_ptr!(fwd_ptrs(g.nodes[m], D), N(n)) &&
    delete_ptr!(rev_ptrs(g.nodes[n], D), N(m)) ||
    error("edge $(Edge(n, m, 0, false)) not found")
    g.edgecount -= 1;
end

remedges!(g::Graph, it) = for x = collect(it); remedge!(g, x); end



#=
##      Graph traversal
=#

"""
    neighbors(g::Graph, n::Integer)

Ids of all neighbors of node `n`.
"""
neighbors(g::Graph, n::Integer) = PtrView(g, n, Both, get_node_id)

"""
    outneighbors(g::Graph, n::Integer)

Ids of nodes towards which node `n` has an edge.
"""
outneighbors(g::Graph, n::Integer) = PtrView(g, n, Forward, get_node_id)

"""
    inneighbors(g::Graph, n::Integer)

Ids of nodes having an edge to node `n`.
"""
inneighbors(g::Graph, n::Integer) = PtrView(g, n, Reverse, get_node_id)

"""
    edgeids(g::Graph, [n::Integer, [m::Integer]])

Iterate over ids of (all, out-, or in-) edges starting at node `n` and
optionally ending in `m`.
"""
edgeids(g::Graph) = Base.flatten(PtrView(g, n, Forward, get_edge_id) for n = nodes(g))

edgeids(g::Graph, n::Integer) = PtrView(g, n, Both, get_edge_id)
outedgeids(g::Graph, n::Integer) = PtrView(g, n, Forward, get_edge_id)
inedgeids(g::Graph, n::Integer) = PtrView(g, n, Reverse, get_edge_id)

# FIXME: edgeids
# edgeids(g::Graph{N,E,D}, n::Integer, m::Integer) where {N,E,D} = EdgeRangeIDView(g.nodes[n], m, D)

"""
    edges(g::Graph, [n::Integer, [m::Integer]])

Iterate over all edges in the graph, or, if `n` is provided, edges that are
adjacent to node `n`. If both `n` and `m` are provided, list edges between those
two nodes.
"""
edges(g::Graph) = EdgeIter(g)
edges(g::Graph, n::Integer) = PtrView(g, n, Both, get_edge)

# FIXME: implement next 4 methods
# edges(g::Graph{N,E,D}, n::Integer, m::Integer) where {N,E,D} = EdgeRangeView(g.nodes[n], n, m, D, Forward)
# edges(g::Graph{N,E,D}, n::Integer, m::UnitRange) where {N,E,D} = EdgeRangeView(g.nodes[n], n, m, D, Forward)
# edges(g::Graph{N,E,D}, n::UnitRange, m::Integer) where {N,E,D} = EdgeRangeView(g.nodes[m], m, n, D, Reverse)
# edges(g::Graph{N,E,D}, n::UnitRange, m::UnitRange) where {N,E,D} = Base.Flatten(EdgeRangeView(g.nodes[i], i, m, Forward, D) for i = n)

"""
    outedges(g::Graph, n::Integer)

Iterate over all edges that start at node `n`.
"""
outedges(g::Graph, n::Integer) = PtrView(g, n, Forward, get_edge)
outedges(g::Graph, n::AbstractVector) = Base.flatten(PtrView(g, i, Forward, get_edge) for i = n)

"""
    inedges(g::Graph, n::Integer)

Iterate over all edges that finish at node `n`.
"""
inedges(g::Graph, n::Integer) = PtrView(g, n, Reverse, get_edge)
inedges(g::Graph, n::AbstractVector) = Base.Flatten(PtrView(g, i, Reverse, get_edge) for i = n)



#=
##      Indexing `Graph` objects
=#

size(g::Graph) = (nodecount(g), nodecount(g))
size(g::Graph, i::Integer) = i <= 2 ? nodecount(g) : 1

# Nodes
getindex(g::Graph, ::Colon) = nodes(g)
getindex(g::Graph, n) = g.nodes[n]

# Edges
getindex(g::Graph, ::Colon, ::Colon) = edges(g)
getindex(g::Graph, n, ::Colon) = outedges(g, n)
getindex(g::Graph, ::Colon, n) = inedges(g, n)
# getindex(g::Graph, n, m) = edges(g, n, m)

# Attributes
getindex(d::AttributeDict, s::Symbol, i) = d[s][i]

function setindex!(d::AttributeDict, v, s::Symbol, i)
    if typeof(d[s]) <: ConstantAttribute
        d[s] = SparseAttribute(d[s])
    elseif typeof(d[s]) <: SparseAttribute && density(d[s]) > .3
        d[s] = DenseAttribute(d[s])
    end
    d[s][i] = v
end

addnodeattr!(g::Graph, s::Symbol, v) = g.nodeattrs[s] = nodeattr(g, v)
addedgeattr!(g::Graph, s::Symbol, v) = g.edgeattrs[s] = edgeattr(g, v)

hasnodeattr(g::Graph, s::Symbol) = haskey(g.nodeattrs, s)
hasedgeattr(g::Graph, s::Symbol) = haskey(g.edgeattrs, s)

# Node attributes
setindex!(g::Graph, v, ::Colon, s::Symbol) = 
setindex!(g::Graph, v, i, s::Symbol) = g.nodeattrs[s, i] = v

getindex(g::Graph, ::Colon, s::Symbol) = g.nodeattrs[s]
getindex(g::Graph, i, s::Symbol) = g.nodeattrs[s, i]

# Edge atrributes
setindex!(g::Graph, v, ::Colon, ::Colon, s::Symbol) = addnodeattr!(g, s, v)
setindex!(g::Graph, v, i::Integer, ::Colon, s::Symbol) = g.edgeattrs[s, collect(outedgeids(g, i))] = v
setindex!(g::Graph, v, ::Colon, i::Integer, s::Symbol) = g.edgeattrs[s, collect(inedgeids(g, i))] = v
# setindex!(g::Graph, v, i::Integer, j::Integer, s::Symbol) = g.edgeattrs[s, edgeids(g, i, j)] = v
setindex!(g::Graph, v, e::Edge, s::Symbol) = g.edgeattrs[s, e.id] = v

getindex(g::Graph, ::Colon, ::Colon, s::Symbol) = addedgeattr!(g, s, v)
getindex(g::Graph, i::Integer, ::Colon, s::Symbol) = g.edgeattrs[s, collect(outedgeids(g, i))]
getindex(g::Graph, ::Colon, i::Integer, s::Symbol) = g.edgeattrs[s, collect(inedgeids(g, i))]
# getindex(g::Graph, i::Integer, j::Integer, s::Symbol) = g.edgeattrs[s][edgeids(g, i, j)]
getindex(g::Graph, e::Edge, s::Symbol) = g.edgeattrs[s, e.id]



#=
##      Convenience syntax
=#

function Graph(; directed=true, multigraph=true, nodecount=0,
             nodeids=UInt32, edgeids=UInt32)
    N, E = nodeids::Type, edgeids::Type
    D = directed ? Forward : Both
    M = multigraph ? Multi : Simple
    g = Graph{N,E,D,M}()
    addnodes!(g, nodecount)
    return g
end

