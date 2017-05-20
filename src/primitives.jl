#= Node and edge types.

Each graph consists of `Node`s that store information about connections with
each other using pointers of type `NodePtr`.

Based on those pointers and their corresponding nodes, `Edge` instances
are generated dynamically upon user's request.
=#

import Base: isless, ==

"""
    NodePtr{N,E}

Internal type for storing information about connections in the graph:
  * `node` — id of target node,
  * `id`   — id of the corresponding edge.
"""
immutable NodePtr{N,E}
    node :: N
    id   :: E
end

# `NodePtr` instances are compared by IDs of nodes they point to.
isless{N,E}(e::NodePtr{N,E}, f::NodePtr{N,E}) = <(e.node, f.node)
isless{N,E}(e::NodePtr{N,E}, f::N) = <(e.node, f)
isless{N,E}(e::N, f::NodePtr{N,E}) = <(e, f.node)
=={N,E}(e::N, f::NodePtr{N,E}) = ==(e, f.node)
=={N,E}(f::NodePtr{N,E}, e::N) = ==(e, f.node)


"""
    Node{N,E}

Stores information about a single node. Its fields `forward` and `reverse`
hold vectors of pointers to other nodes.
"""
immutable Node{N,E}
    forward :: Vector{NodePtr{N,E}}
    reverse :: Vector{NodePtr{N,E}}

    Node(a, b) = new(a, b)
    Node() = new(NodePtr{N,E}[], NodePtr{N,E}[])
end

Node{N,E}(a::Vector{NodePtr{N,E}}, b::Vector{NodePtr{N,E}}) = Node{N,E}(a, b)


"""
    Edge{N1,N2,E}

A single edge in the graph. It has the following fields:
  * `source` — id of the source node,
  * `target` — id of the target node,
  * `id`     — this edge's own unique id.
"""
immutable Edge{N1,N2,E,D<:DirParam}
    source :: N1
    target :: N2
    id     :: E
end

Edge{N1,N2,E,D}(n::N1, p::NodePtr{N2,E}, ::Type{D}, ::Type{Forward}) =
    Edge{N1,N2,E,D}(n, p.node, p.id)
Edge{N1,N2,E,D}(n::N1, p::NodePtr{N2,E}, ::Type{D}, ::Type{Reverse}) =
    Edge{N2,N1,E,D}(p.node, n, p.id)
Edge{N1,N2,E,D}(n::N1, p::NodePtr{N2,E}, ::Type{D}, ::Type{Both}) =
    Edge{N2,N1,E,Both}(n, p.node, p.id)

# immutable Edge{N1,N2,E}
#     source :: N1
#     target :: N2
#     id     :: E
# end
#
# Edge(n, p::NodePtr, ::Type{Forward}) = Edge(n, p.node, p.id)
# Edge(n, p::NodePtr, ::Type{Reverse}) = Edge(p.node, n, p.id)
