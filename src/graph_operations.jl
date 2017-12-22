## Simple graph manipulations (nodes/edges/attributes) ##

#=
##      Operations with nodes
=#

"""
    nodes(g::Graph)

Indices of all nodes in the graph.
"""
nodes(g::Graph) = 1:length(g.nodes)

"""
    nodecount(g::Graph)

Count nodes in the graph.
"""
nodecount(g::Graph) = length(g.nodes)

"""
    addnode!(g::Graph[, count])

Add one or several nodes to the graph.
"""
function addnode!(g::Graph{N,E}) where {N,E}
    @assert(nodecount(g) < typemax(N),
            "integer overflow; try using a larger type for node ids")
    push!(g.nodes, Node{N,E}())
    return nodecount(g)
end

function addnode!(g::Graph, count::Integer)
    for i = 1:count
        addnode!(g)
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
    edgecount(g::Graph)

Count edges in the graph.
"""
edgecount(g::Graph) = g.edgecount

size(g::Graph) = (nodecount(g), edgecount(g))

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
    @assert(g.edgemaxid < typemax(E),
            "integer overflow; try using a larger type for edge ids")
    g.edgemaxid += one(E)
    return NodePtr(m, g.edgemaxid), NodePtr(n, g.edgemaxid)
end

function new_ptr_pair!(g::Graph{N,E}, n::N, m::N) where {N,E<:Void}
    @_inline_meta
    return NodePtr(m, nothing), NodePtr(n, nothing)
end

"""
    addedge!{N,E}(g::Graph{N,E}, n::Integer, m::Integer)

Add an edge between nodes `n` and `m` in graph `g`.
"""
function addedge!(g::MultiGraph{N,E,D}, n::Integer, m::Integer) where {N,E,D}
    fwd, rev = new_ptr_pair!(g, N(n), N(m))
    add_ptr!(fwd_ptrs(g.nodes[n], D), fwd)
    add_ptr!(rev_ptrs(g.nodes[m], D), rev)
    g.edgecount += 1;
end

function addedge!(g::SimpleGraph{N,E,D}, n::Integer, m::Integer) where {N,E,D}
    fwd, rev = new_ptr_pair!(g, N(n), N(m))
    add_one_ptr!(fwd_ptrs(g.nodes[n], D), fwd) &&
    add_one_ptr!(rev_ptrs(g.nodes[m], D), rev) ||
    error("graph already contains edge $n → $m")
    g.edgecount += 1;
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
##      Operations with attributes
=#

hasnodeattr(g::Graph, s::Symbol) = haskey(g.nodeattrs, s)
hasedgeattr(g::Graph, s::Symbol) = haskey(g.edgeattrs, s)

getattr(d::AttributeDict, s::Symbol, len::Integer) = (sizehint!(d[s], len); d[s])
getattrn(d::AttributeDict, s::Symbol, n::Integer) = d[s][n]
getattrg(d::AttributeDict, s::Symbol, g) = (d[s][i] for i = g)

setattr!(d::AttributeDict, s::Symbol, x) = d[s] = attribute(x)


function setattr!(d::AttributeDict, s::Symbol, ids::Integer, x)
    if typeof(d[s])<:ConstantAttribute
        d[s] = SparseAttribute(d[s])
    end
    d[s][ids] = x
end

function setattr!(d::AttributeDict, s::Symbol, ids::T, x) where {T<:AbstractVector}
    if typeof(d[s])<:ConstantAttribute
        d[s] = SparseAttribute(d[s])
    end
    for i = ids
        d[s][i] = x
    end
end



function newnodeattr(g::Graph, t::Type=SparseAttribute, default=nothing)
    if t == DenseAttribute
        nothing
    end
end

newnodeattr(g::Graph, value) = fill(value, g.nodemaxid)
newnodeattr(g::Graph, fn::Function) = [fn(g, i) for i = nodes(g)]



#=
##      Indexing syntax
=#

# Nodes
getindex(g::Graph, ::Colon) = nodes(g)
getindex(g::Graph, n) = g.nodes[n]

# Edges
getindex(g::Graph, ::Colon, ::Colon) = edges(g)
getindex(g::Graph, n, ::Colon) = outedges(g, n)
getindex(g::Graph, ::Colon, n) = inedges(g, n)
getindex(g::Graph, n, m) = edges(g, n, m)

# Node attributes
getindex(g::Graph, ::Colon, s::Symbol) = getattr(g.nodeattrs, s, nodecount(g))
getindex(g::Graph, n::Integer, s::Symbol) = getattrn(g.nodeattrs, s, n)
setindex!(g::Graph, x, ::Colon, s::Symbol) = setattr!(g.nodeattrs, s, x)
setindex!(g::Graph, x, n::Integer, s::Symbol) =
    (checkbounds(g.nodes, n); setattr!(g.nodeattrs, s, n, x))
setindex!(g::Graph, x, n::UnitRange, s::Symbol) = setattr!(g.nodeattrs, s, n, x)

# Edge atrributes
getindex(g::Graph, ::Colon, ::Colon, s::Symbol) = getattr(g.edgeattrs, s, edgecount(g))
getindex(g::Graph, n::Integer, ::Colon, s::Symbol) = getattrg(g.edgeattrs, s, outedgeids(g, n))
getindex(g::Graph, ::Colon, n::Integer, s::Symbol) = getattrg(g.edgeattrs, s, inedgeids(g, n))
getindex(g::Graph, n::Integer, m::Integer, s::Symbol) = getattrg(g.edgeattrs, s, edgeids(g, n, m))
getindex(g::Graph, e::Edge, s::Symbol) = getattr(g.edgeattrs, s, e.id)

setindex!(g::Graph, x, ::Colon, ::Colon, s::Symbol) = setattr!(g.edgeattrs, s, x)
setindex!(g::Graph, x, n::Integer, ::Colon, s::Symbol) = setattr!(g.edgeattrs, s, outedgeids(g, n), x)  #+g
setindex!(g::Graph, x, ::Colon, n::Integer, s::Symbol) = setattr!(g.edgeattrs, s, inedgeids(g, n), x)  #+g
setindex!(g::Graph, x, n::Integer, m::Integer, s::Symbol) = setattr!(g.edgeattrs, s, edgeids(g, n, m), x)  #+g
setindex!(g::Graph, x, e::Edge, s::Symbol) = setattr!(g.edgeattrs, s, e.id, x)



#=
##      Convenience syntax
=#

function Graph(; directed=true, multigraph=true, nodecount=0,
             nodeids = UInt32, edgeids = UInt32)
    N, E = nodeids::Type, edgeids::Type
    D = directed ? Forward : Both
    M = multigraph ? Multi : Simple
    g = Graph{N,E,D,M}()
    addnode!(g, nodecount)
    return g
end

# function addnode!(g::Graph, attrs::Dict{Symbol,Any})
#     n = addnode!(g)
#     for (a, v) = attrs
#         g[n, a] = v
#     end
#     n
# end
#
# function addedge!(g::Graph, n::Integer, m::Integer, attrs::Dict)
#     e = addedge!(g, n, m)
#     for (a, v) = attrs
#         setattr!(g.edgeattrs, a, e, v)
#     end
#     e
# end
