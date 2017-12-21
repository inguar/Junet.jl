#= Node and edge types

Each graph consists of `Node`s that store information about connections with
each other using pointers of type `NodePtr`.

Based on those pointers and their corresponding nodes, `Edge` instances
are generated dynamically upon user's request.
=#

"""
    NodePtr{N,E}

Internal type for storing information about connections in the graph:
  * `node` — id of target node,
  * `id`   — id of the corresponding edge.

`NodePtr` instances are compared by IDs of nodes they point to.
"""
struct NodePtr{N,E}
    node :: N
    id   :: E
end

isless(e::NodePtr{N,E}, f::NodePtr{N,E}) where {N,E} = <(e.node, f.node)
isless(e::NodePtr{N,E}, f::N) where {N,E} = <(e.node, f)
isless(e::N, f::NodePtr{N,E}) where {N,E} = <(e, f.node)

==(e::N, f::NodePtr{N,E}) where {N,E} = ==(e, f.node)
==(f::NodePtr{N,E}, e::N) where {N,E} = ==(e, f.node)


"""
    Node{N,E}

A single node in the graph.
Its `forward` and `reverse` fields hold vectors of pointers to other nodes.
"""
struct Node{N,E}
    forward :: Vector{NodePtr{N,E}}
    reverse :: Vector{NodePtr{N,E}}
end

Node{N,E}() where {N,E} = Node{N,E}(NodePtr{N,E}[], NodePtr{N,E}[])

fwd_ptrs(n::Node) = n.forward
fwd_ptrs(n::Node, ::Type{Forward}) = n.forward
fwd_ptrs(n::Node, ::Type{Reverse}) = n.reverse
fwd_ptrs(n::Node, ::Type{Both}) = n.forward

rev_ptrs(n::Node) = n.reverse
rev_ptrs(n::Node, ::Type{Forward}) = n.reverse
rev_ptrs(n::Node, ::Type{Reverse}) = n.forward
rev_ptrs(n::Node, ::Type{Both}) = n.reverse

ptr_length(n::Node, ::Type{Forward}) = length(n.forward)
ptr_length(n::Node, ::Type{Reverse}) = length(n.reverse)
ptr_length(n::Node, ::Type{Both}) = length(n.forward) + length(n.reverse)

findfirst_ptr(x::Vector{NodePtr{N,E}}, i::N) where {N,E} = findfirst(x, N(i))

has_ptr(x::Vector{NodePtr{N,E}}, n::N) where {N,E} =
    let i = searchsortedlast(x, n)
        i != 0 && x[i] == n
    end

get_ptr(n::Node, i::Integer, ::Type{Forward}) = n.forward[i]
get_ptr(n::Node, i::Integer, ::Type{Reverse}) = n.reverse[i]
get_ptr(n::Node, i::Integer, ::Type{Both}) =
    let l = length(n.reverse)
        if i > l
            return n.forward[i - l]
        else
            return n.reverse[i]
        end
    end

function add_ptr!(vec::Vector{T}, val::T) where {T}
    i = searchsortedlast(vec, val) + 1
    insert!(vec, i, val)
end

"""
    insertsortedone!(vec, val)

Insert `val` into a sorted vector `vec` if it is not there already.
Returns `true` or `false` depending on whether it was inserted.
"""
function add_one_ptr!(vec::Vector{T}, val::T) where {T}
    i = searchsortedlast(vec, val)
    @inbounds if i == 0 || vec[i] != val
        insert!(vec, i + 1, val)
        return true
    else
        return false
    end
end

"""
    delete_ptr!()

Internal function to remove a matching NodePtr from a Vector.
"""
function delete_ptr!(ptrs::Vector{NodePtr{N,E}}, nid::N, eid::E) where {N,E}
    @inbounds for i = searchsorted(ptrs, nid)
        if ptrs[i].id == eid
            deleteat!(ptrs, i)
            return true
        end
    end
    return false
end

function delete_ptr!(ptrs::Vector{NodePtr{N,E}}, nid::N) where {N,E}
    i = searchsortedlast(ptrs, nid)
    if i > 0 && ptrs[i] == nid
        deleteat!(ptrs, i)
        return true
    end
    return false
end

function swap_ptr!(ptrs::Vector{NodePtr{N,E}}, nid::N, eid::E, new_nid::N) where {N,E}
    @_inline_meta
    delete_ptr!(ptrs, nid, eid)
    add_ptr!(ptrs, NodePtr{N,E}(new_nid, eid))
end


"""
    Edge{N,E}

A single edge in the graph. It has the following fields:
  * `source` — id of the source node,
  * `target` — id of the target node,
  * `id`     — its own unique id,
  * `isdir`  — whether it is directed.
"""
struct Edge{N,E}
    source :: N
    target :: N
    id     :: E
    isdir  :: Bool
end
