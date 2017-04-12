# Pretty printing of graph-related types.

import Base: size, show


size(g::Graph) = (nodecount(g), edgecount(g))

memsize(g::Graph) =
    sizeof(g) + sizeof(g.nodes) +
    sum(sizeof(n.forward) + sizeof(n.reverse)  for n = g.nodes) +
    sizeof(g.nodeattrs) + sizeof(g.edgeattrs)

plural(count, name) = string(count) * " " * name * (count != 1 ? "s" : "")

show(io::IO, g::Graph) = print(io,
    (isdirected(g) ? "Directed " : "Undirected ") *
    (ismultigraph(g) ? "multigraph " : "graph ") *
    "with " * plural(nodecount(g), "node") *
    " and " * plural(edgecount(g), "edge"))

# TODO Add the `summary` function like in igraph

show(io::IO, n::Node) = print(io, "Node with $(length(n.forward) + length(n.reverse)) adjacent edges")

show(io::IO, e::NodePtr) = print(io, "→ $(e.node) (#$(e.id))")
show{N,E<:Void}(io::IO, e::NodePtr{N,E}) = print(io, "→ $(e.node)")

show{N1,N2,E<:Integer,D<:Directed}(io::IO, e::Edge{N1,N2,E,D}) =
    print(io, "$(e.source) → $(e.target) (#$(e.id))")
show{N1,N2,E<:Void,D<:Directed}(io::IO, e::Edge{N1,N2,E,D}) =
    print(io, "$(e.source) → $(e.target)")
show{N1,N2,E<:Integer,D<:Undirected}(io::IO, e::Edge{N1,N2,E,D}) =
    print(io, "$(e.source) ←→ $(e.target) (#$(e.id))")
show{N1,N2,E<:Void,D<:Undirected}(io::IO, e::Edge{N1,N2,E,D}) =
    print(io, "$(e.source) ←→ $(e.target)")

# show(io::IO, e::Edge) = print(io, "$(e.source) → $(e.target) (#$(e.id))")

show{N,E}(io::IO, g::Base.Generator{Vector{NodePtr{N,E}}}) =
    print(io, "Edge generator with " * plural(length(g), "element"))

# show{N}(io::IO, ::Type{NodeIDView{N}}) = print("NodeIDView{$N}")
# show{E}(io::IO, ::Type{EdgeIDView{E}}) = print("EdgeIDView{$E}")
# show{N,E}(io::IO, ::Type{EdgeViewFw{N,E}}) = print("EdgeView{$N,$E}")
# show{N,E}(io::IO, ::Type{EdgeViewRv{N,E}}) = print("EdgeView{$N,$E}")
