## Graph type definition ##

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
mutable struct Graph{N<:Integer,E<:Union{Integer,Void},D<:DirParam,M<:MultiParam}
    nodes::Vector{Node{N,E}}
    nodeattrs::AttributeDict
    edgemaxid::E
    edgecount::Int
    edgeattrs::AttributeDict
end

const LightGraph = Graph{N,Void,D,M} where {N,D,M}

const DirectedGraph   = Graph{N,E,<:Directed,M} where {N,E,M}
const UndirectedGraph = Graph{N,E,<:Undirected,M} where {N,E,M}

const MultiGraph  = Graph{N,E,D,Multi} where {N,E,D}
const SimpleGraph = Graph{N,E,D,Simple} where {N,E,D}

Graph{N,E,D,M}() where {N,E,D,M} = Graph{N,E,D,M}(
        Node{N,E}[], AttributeDict(),          # nodes
        defval(E), zero(Int), AttributeDict()  # edges
    )

Graph{N,E,D,M}(g::Graph) where {N,E,D,M} = Graph{N,E,D,M}(
        g.nodes, g.nodeattrs,                  # nodes
        g.edgemaxid, g.edgecount, g.edgeattrs  # edges
    )

dirview(g::Graph{N,E,D_,M}, D::Type{<:DirParam}) where {N,E,D_,M} = Graph{N,E,D,M}(g)

"""
    isdirected(g::Graph)

Check whether graph is directed.
"""
isdirected(::DirectedGraph)   = true
isdirected(::UndirectedGraph) = false

"""
    ismultigraph(g::Graph)

Check whether graph is permitted to contain mutliple edges and/or selfloops.
"""
ismultigraph(::MultiGraph)  = true
ismultigraph(::SimpleGraph) = false

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
reverse(g::Graph{N,E,Forward}) where {N,E} = dirview(g, Reverse)
reverse(g::Graph{N,E,Reverse}) where {N,E} = dirview(g, Forward)
reverse(g::UndirectedGraph) = g
transpose(g::Graph) = reverse(g)
