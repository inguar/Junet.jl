## Methods giving basic information about graphs ##

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
    edgecount(g::Graph)

Count edges in the graph.
"""
edgecount(g::Graph) = g.edgecount

size(g::Graph) = (nodecount(g), edgecount(g))

"""
    maxedgecount(g::Graph)

Maximum number of edges possible in a graph having no multiple edges and self-loops.
"""
maxedgecount(g::DirectedGraph)   = (n = nodecount(g); n * (n - 1))
maxedgecount(g::UndirectedGraph) = (n = nodecount(g); div(n * (n - 1), 2))
