# Graph type and all basic manipulations on it.

import Base: reverse, getindex, setindex!

"""
    Graph{N,E,D,M}

Type for storing graphs. Its fields have mostly self-explanatory names
(field marked with an asterisk is for internal use only):
  * `nodes`      — vector with nodes in the graph
  * `nodeattrs`  — dictionary with node attributes
  * `edgemaxid`* — largest edge id
  * `edgecount`  — count of edges in the graph
  * `edgeattrs`  — dictionary with edge attributes

There are four type parameters:
  * `N` — integer type used for node ids
  * `E` — integer type used for edge ids, `Void` can also be used to save space
  * `D` — singleton type indicating whether the graph is directed
     - `Directed`   — directed graph (default)
     - `Undirected` — undirected graph
  * `M` — singleton type indicating whether multiple edges and self-loops
    are allowed
     - `Multi`  — multiple edges and self-loops allowed, i.e. graph
        is a multigraph (default)
     - `Simple` — only single edges between pais of different nodes allowed,
        i.e. graph is simple

There is a couple of predefined type aliases you can use for dispatch in your
functions: `DirectedGraph` or `UndirectedGraph` (w.r.t graph directedness), and
`MultiGraph` or `SimpleGraph` (w.r.t. being a multigraph).

"""
type Graph{N<:Integer,E<:Union{Integer,Void},D<:DirParam,M<:MultiParam}
    nodes      :: Vector{Node{N,E}}
    nodeattrs  :: AttributeDict
    edgemaxid  :: E
    edgecount  :: Int
    edgeattrs  :: AttributeDict

    Graph() = new(
        Node{N,E}[], AttributeDict(),          # nodes
        null(E), zero(Int), AttributeDict()    # edges
    )

    Graph(g::Graph) = new(
        g.nodes, g.nodeattrs,                  # nodes
        g.edgemaxid, g.edgecount, g.edgeattrs  # edges
    )
end

dirview{N,E,D_,M}(g::Graph{N,E,D_,M}, D::Type) = Graph{N,E,D,M}(g)
dirtype{N,E,D}(g::Graph{N,E,D}) = D

typealias LightGraph{N,E<:Void,D,M}            Graph{N,E,D,M}

typealias DirectedGraph{N,E,D<:Directed,M}     Graph{N,E,D,M}
typealias DirectedFwGraph{N,E,D<:Forward,M}    Graph{N,E,D,M}
typealias DirectedRvGraph{N,E,D<:Reverse,M}    Graph{N,E,D,M}
typealias UndirectedGraph{N,E,D<:Undirected,M} Graph{N,E,D,M}

typealias MultiGraph{N,E,D,M<:Multi}           Graph{N,E,D,M}
typealias SimpleGraph{N,E,D,M<:Simple}         Graph{N,E,D,M}

"""
    isdirected(g::Graph)

Check whether graph is directed.
"""
isdirected(g::DirectedGraph)   = true
isdirected(g::UndirectedGraph) = false

"""
    ismultigraph(g::Graph)

Check whether graph is permitted to contain mutliple edges and/or selfloops.
"""
ismultigraph(g::MultiGraph)  = true
ismultigraph(g::SimpleGraph) = false

"""
    directed(g::Graph)

A view on the graph that makes it directed. Made without copying.
"""
directed(g::UndirectedGraph) = dirview(g, Forward)
directed(g::DirectedGraph)   = g

"""
    undirected(g::Graph)

A view on the graph that makes it undirected. Made without copying.
"""
undirected(g::DirectedGraph)   = dirview(g, Both)
undirected(g::UndirectedGraph) = g

"""
    reverse(g::Graph)

A view on the graph where each edge is reversed.
"""
reverse(g::DirectedFwGraph) = dirview(g, Reverse)
reverse(g::DirectedRvGraph) = dirview(g, Forward)
reverse(g::UndirectedGraph) = g


#=
        Operations with nodes
=#

"""
    nodecount(g::Graph)

Count nodes in the graph.
"""
nodecount(g::Graph) = length(g.nodes)

"""
    nodes(g::Graph)

Indices of all nodes in the graph.
"""
nodes(g::Graph) = 1:length(g.nodes)

"""
    addnode!(g::Graph, [count])

Add one or several nodes to the graph.
"""
function addnode!{N,E}(g::Graph{N,E})
    id = N(nodecount(g) + 1)
    @assert(id > zero(N), "Integer overflow; try using a larger type for node ids")
    push!(g.nodes, Node{N,E}())
    return id
end

function addnode!(g::Graph, count::Integer)
    # sizehint!(g.nodes, nodecount(g) + count)
    for i = 1:count
        addnode!(g)
    end
end

"""
    remnode!(g::Graph, n::Integer)

Remove node `n` from the graph.
"""
function remnode!{N,E}(g::Graph{N,E}, u::Integer)
    deleteat!(g.nodes, u)
    #FIXME: remove references to it from the other nodes!
end


#=
     Operations with edges
=#

"""
    edgecount(g::Graph)

Count edges in the graph.
"""
edgecount(g::Graph) = g.edgecount

"""
    hasedge(g::Graph, n::Integer, m::Integer)

Check if graph `g` has an edge between nodes `n` and `m`.
"""
hasedge{N}(g::DirectedFwGraph{N}, n::Integer, m::Integer) = begin
    i = searchsortedlast(g.nodes[n].forward, N(m))
    return i != 0 && g.nodes[n].forward[i].node == N(m)
end

hasedge{N}(g::DirectedRvGraph{N}, n::Integer, m::Integer) = begin
    i = searchsortedlast(g.nodes[n].reverse, N(m))
    return i != 0 && g.nodes[n].reverse[i].node == N(m)
end

hasedge{N}(g::UndirectedGraph{N}, n::Integer, m::Integer) =
    g.nodes[n].forward[searchsortedlast(g.nodes[n].forward, N(m))].node == N(m) ||
    g.nodes[n].reverse[searchsortedlast(g.nodes[n].reverse, N(m))].node == N(m)

# FIXME: test the undiredted graph implementation

"""
    addedge!{N,E}(g::Graph{N,E}, n::Integer, m::Integer)

Add an edge between nodes `n` and `m` in graph `g`.
"""
function addedge!{N,E}(g::MultiGraph{N,E}, n::Integer, m::Integer)
    id = g.edgemaxid + one(E)
    @assert(id > zero(E), "Integer overflow; try using a larger type for edge ids")
    insertsorted!(g.nodes[n].forward, NodePtr(N(m), id))
    insertsorted!(g.nodes[m].reverse, NodePtr(N(n), id))
    g.edgecount += 1
    g.edgemaxid = id
end

function addedge!{N,E}(g::SimpleGraph{N,E}, n::Integer, m::Integer)
    id = g.edgemaxid + one(E)
    @assert(id > zero(E), "Integer overflow; try using a larger type for edge ids")
    if insertsortedone!(g.nodes[n].forward, NodePtr(N(m), id)) &&
            insertsortedone!(g.nodes[m].reverse, NodePtr(N(n), id))
        error("Graph already contains edge $n → $m")
    else
        g.edgecount += 1
        g.edgemaxid = id
    end
end

function addedge!{N,E<:Void}(g::MultiGraph{N,E}, n::Integer, m::Integer)
    insertsorted!(g.nodes[n].forward, NodePtr(N(m), nothing))
    insertsorted!(g.nodes[m].reverse, NodePtr(N(n), nothing))
    g.edgecount += 1
end

"""
    remedge!(g::Graph, e::Edge)

Remove edge `e` from graph `g`.
"""
function remedge!{N,E,D<:Directed}(g::Graph{N,E,D}, e::Edge{N,E})
    direct = g.nodes[e.source].forward
    succ_direct = false
    for i = searchsorted(direct, e.source)
        if direct[i].id == e.id
            deleteat!(direct, i)
            succ_direct = true
            break
        end
    end
    @assert(succ_direct, "Edge $e not found in graph")
    reverse = g.nodes[e.target].reverse
    succ_reverse = false
    for i = searchsorted(reverse, e.target)
        if reverse[i].id == e.id
            deleteat!(reverse, i)
            succ_reverse = true
            break
        end
    end
    @assert(succ_reverse, "Reverse image of edge $e not found")
    g.edgecount -= 1
end

remedge!{N,E,D<:Reverse,M}(g::Graph{N,E,D,M}, e::Edge{N,E}) = remedge!(g, reverse(e))

function remedge!{N,E,D<:Undirected,M}(g::Graph{N,E,D,M}, e::Edge{N,E})
    direct = g.nodes[e.source].forward
    succ = 0
    for i = searchsorted(direct, e.target)
        if direct[i].id == e.id
            deleteat!(direct, i)
            succ = 1     # direct-reverse
            break
        end
    end
    if succ == 0
        reverse = g.nodes[e.source].reverse
        for i = searchsorted(reverse, e.target)
            if direct[i].id == e.id
                deleteat!(reverese, i)     # reverse-direct
                succ = 2
                break
            end
        end
    end
    @assert(succ != 0, "Edge $e not found in graph")
    list = succ == 1 ? g.nodes[e.target].reverse : g.nodes[e.target].forward
    succ_reverse = false
    for i = searchsorted(list, e.source)
        if list[i].id == e.id
            deleteat!(list, i)
            succ_reverse = true
            break
        end
    end
    @assert(succ_reverse, "Reverse image of edge $e not found")
    g.edgecount -= 1
end

function remedge!{N,E}(g::UndirectedGraph{N,E}, e::Edge{N,E})
    for i = searchsorted(g.nodes[e.source].forward, e.target)
        if g.nodes[e.source].forward[i].id == e.id
            deleteat!(g.nodes[e.source].forward, i)
            return
        end
    end
    for i = searchsorted(g.nodes[e.source].reverse, e.target)
        if g.nodes[e.source].reverse[i].id == e.id
            deleteat!(g.nodes[e.source].reverse, i)
            return
        end
    end
    error("Edge not found in the graph")
end

function remedge!{N,E,D<:Directed,M<:Simple}(g::Graph{N,E,D,M}, n::Integer, m::Integer)
    # TODO
end



#=
##        Graph traversal
=#

"""
    neighbors(g::Graph, n::Integer)

Ids of all neighbors of node `n`.
"""
neighbors(g::Graph, n::Integer) = NodeIDView(g.nodes[n], Both)

"""
    outneighbors(g::Graph, n::Integer)

Ids of nodes towards which node `n` has an edge.
"""
outneighbors{N,E,D}(g::Graph{N,E,D}, n::Integer) = NodeIDView(g.nodes[n], D)

"""
    inneighbors(g::Graph, n::Integer)

Ids of nodes having an edge to node `n`.
"""
inneighbors{N,E,D}(g::Graph{N,E,D}, n::Integer) = NodeIDView(g.nodes[n], rev(D))

"""
    edgeids(g::Graph, [n::Integer, [m::Integer]])

Iterate over ids of (in-, out-, or all) edges starting at node `n` and
optionally ending in `m`.
"""
edgeids(g::Graph) = Base.flatten(EdgeIDView(g.nodes[n], Forward) for n = nodes(g))

edgeids(g::Graph, n::Integer) = EdgeIDView(g.nodes[n], Both)
outedgeids{N,E,D}(g::Graph{N,E,D}, n::Integer) = EdgeIDView(g.nodes[n], D)
inedgeids{N,E,D}(g::Graph{N,E,D}, n::Integer)  = EdgeIDView(g.nodes[n], rev(D))

edgeids{N,E,D}(g::Graph{N,E,D}, n::Integer, m::Integer) = EdgeRangeIDView(g.nodes[n], m, D)

"""
    edges(g::Graph, [n::Integer, [m::Integer]])

Iterate over all edges in the graph, or, if `n` is provided, edges that are
adjacent to node `n`. If both `n` and `m` are provided, list edges between those
two nodes.
"""
@inline edges{N,E,D}(g::Graph{N,E,D}) = (Edge(i, j, Forward, D) for i = nodes(g) for j = g.nodes[i].forward)

edges(g::Graph, n::Integer) = EdgeView(g.nodes[n], n, Both, Forward)
edges{N,E,D}(g::Graph{N,E,D}, n::Integer, m::Integer) = EdgeRangeView(g.nodes[n], n, m, D, Forward)
edges{N,E,D}(g::Graph{N,E,D}, n::Integer, m::UnitRange) = EdgeRangeView(g.nodes[n], n, m, D, Forward)
edges{N,E,D}(g::Graph{N,E,D}, n::UnitRange, m::Integer) = EdgeRangeView(g.nodes[m], m, n, D, Reverse)
edges{N,E,D}(g::Graph{N,E,D}, n::UnitRange, m::UnitRange) = Base.Flatten(
    EdgeRangeView(g.nodes[i], i, m, Forward, D) for i = n )

"""
    outedges(g::Graph, n::Integer)

Iterate over all edges that start at node `n`.
"""
outedges{N,E,D}(g::Graph{N,E,D}, n::Integer) = EdgeView(g.nodes[n], n, D, Forward)
outedges{N,E,D}(g::Graph{N,E,D}, n::UnitRange) = Base.flatten(
    EdgeView(g.nodes[i], i, D, Forward) for i = n )

"""
    inedges(g::Graph, n::Integer)

Iterate over all edges that finish at node `n`.
"""
inedges{N,E,D}(g::Graph{N,E,D}, n::Integer) = EdgeView(g.nodes[n], n, rev(D), Reverse)
inedges{N,E,D}(g::Graph{N,E,D}, n::UnitRange) = Base.Flatten(
    EdgeView(g.nodes[i], i, rev(D), Reverse) for i = n )



#=
##        Operations with attributes
=#

hasnodeattr(g::Graph, s::Symbol) = haskey(g.nodeattrs, s)
hasedgeattr(g::Graph, s::Symbol) = haskey(g.edgeattrs, s)

getattr(d::AttributeDict, s::Symbol, len::Integer) = (sizehint!(d[s], len); d[s])
getattrn(d::AttributeDict, s::Symbol, n::Integer) = d[s][n]
getattrg(d::AttributeDict, s::Symbol, g) = (d[s][i] for i=g)

setattr!(d::AttributeDict, s::Symbol, x) = d[s] = attribute(x)

function setattr!(d::AttributeDict, s::Symbol, idx::Integer, x)
    if typeof(d[s]) <: ConstantAttribute
        d[s] = SparseAttribute(d[s])
    end
    d[s][idx] = x
end

function setattrg!(d::AttributeDict, s::Symbol, ids, x)
    if typeof(d[s]) <: ConstantAttribute
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
newnodeattr(g::Graph, fn::Function) = [fn(g, i) for i=nodes(g)]



#=
        Indexing syntax
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

# Edge atrributes
getindex(g::Graph, ::Colon, ::Colon, s::Symbol) = getattr(g.edgeattrs, s, edgecount(g))
getindex(g::Graph, n::Integer, ::Colon, s::Symbol) = getattrg(g.edgeattrs, s, outedgeids(g, n))
getindex(g::Graph, ::Colon, n::Integer, s::Symbol) = getattrg(g.edgeattrs, s, inedgeids(g, n))
getindex(g::Graph, n::Integer, m::Integer, s::Symbol) = getattrg(g.edgeattrs, s, edgeids(g, n, m))

setindex!(g::Graph, x, ::Colon, ::Colon, s::Symbol) = setattr!(g.edgeattrs, s, x)
setindex!(g::Graph, x, n::Integer, ::Colon, s::Symbol) = setattrg!(g.edgeattrs, s, outedgeids(g, n), x)
setindex!(g::Graph, x, ::Colon, n::Integer, s::Symbol) = setattrg!(g.edgeattrs, s, inedgeids(g, n), x)
setindex!(g::Graph, x, n::Integer, m::Integer, s::Symbol) = setattrg!(g.edgeattrs, s, edgeids(g, n, m), x)




#=
        Convenience syntax
=#

function Graph(; directed=true, multigraph=true, nodecount=0,
                 nodeids=UInt32, edgeids=UInt32)
    N, E = nodeids::Type, edgeids::Type
    D = directed ? Forward : Both
    M = multigraph ? Multi : Simple
    g = Graph{N,E,D,M}()
    addnode!(g, nodecount)
    return g
end

function addnode!(g::Graph, attrs::Dict{Symbol,Any})
    n = addnode!(g)
    for (a, v) = attrs
        g[n, a] = v
    end
    n
end

function addedge!(g::Graph, n::Integer, m::Integer, attrs::Dict{Symbol,Any})
    e = addedge!(g, n, m)
    for (a, v) = attrs
        setattr!(g.edgeattrs, a, e, v)
    end
    e
end
