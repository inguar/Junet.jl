degree(g::Graph{N,E,D}, n::Integer) where {N,E,D} = ptr_length(g.nodes[n], dir_xor(D, Both))
degree(g::Graph) = [degree(g, i) for i = nodes(g)]

indegree(g::Graph) = [indegree(g, i) for i = nodes(g)]
indegree(g::Graph{N,E,D}, n::Integer) where {N,E,D} = ptr_length(g.nodes[n], dir_xor(D, Reverse))

outdegree(g::Graph{N,E,D}, n::Integer) where {N,E,D} = ptr_length(g.nodes[n], dir_xor(D, Forward))
outdegree(g::Graph) = [outdegree(g, i) for i = nodes(g)]

# TODO giantcomponent, components, componentcount

is_isolate(g::Graph, n::Integer) = degree(g, n) == 0
isolates(g::Graph) = [i for i = nodes(g) if is_isolate(g, i)]
isolatecount(g::Graph) = count(i -> is_isolate(g, i), nodes(g))

# See https://en.wikipedia.org/wiki/Vertex_(graph_theory)#Types_of_vertices

"""
or `pendant`
"""
is_leaf(g::Graph, n::Integer) = degree(g, n) == 1
leaves(g::Graph) = [i for i = nodes(g) if is_leaf(g, i)]
leafcount(g::Graph) = count(i -> is_leaf(g, i), nodes(g))

"""
In undirected graphs, there can't be any sources or sinks.
"""
is_source(g::DirectedGraph, n::Integer)  = indegree(g, n) == 0 && outdegree(g, n) > 0
is_source(g::UndirectedGraph, ::Integer) = false
sources(g::Graph) = [i for i = nodes(g) if is_source(g, i)]
sourcecount(g::Graph) = count(i -> is_source(g, i), nodes(g))

is_sink(g::DirectedGraph, n::Integer)  = outdegree(g, n) == 0 && indegree(g, n) > 0
is_sink(g::UndirectedGraph, ::Integer) = false
sinks(g::Graph) = [i for i = nodes(g) if is_sink(g, i)]
sinkcount(g::Graph) = count(i -> is_sink(g, i), nodes(g))
