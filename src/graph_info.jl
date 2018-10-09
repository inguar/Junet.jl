## Methods giving basic information about graphs ##

"""
    memsize(g::Graph)

Approximate size of `g` in memory, in bytes.
"""
memsize(g::Graph) =
    sizeof(g) + sizeof(g.nodes) +
    sum(Int[sizeof(n.forward) + sizeof(n.reverse) for n = g.nodes]) +
    sizeof(g.nodeattrs) + sizeof(g.edgeattrs)

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

# Matrix-stype size of Graph
size(g::Graph) = (nodecount(g), nodecount(g))
size(g::Graph, i::Integer) = i <= 2 ? nodecount(g) : 1

"""
    edgecount(g::Graph)

Count edges in the graph.
"""
edgecount(g::Graph) = g.edgecount

"""
    maxedgecount(g::Graph)

Maximum number of edges possible in a graph having no multiple edges and self-loops.
"""
maxedgecount(g::DirectedGraph)   = (n = nodecount(g); n * (n - 1))
maxedgecount(g::UndirectedGraph) = (n = nodecount(g); div(n * (n - 1), 2))
