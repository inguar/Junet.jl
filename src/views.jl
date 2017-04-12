# Lightweight views on node information

import Base: length, size, getindex, @_propagate_inbounds_meta

"""
    AbstractNodePtrView{T,1,D}

Abstract type for views onto vectors of `NodePtr` elements. Its children
behave like `Vector{T}`, where each value is computed on demand from the
underlying `NodePtr` instance.
`D` specifies which direction to associate with the underlying data.
"""
abstract AbstractNodePtrView{T,_,D<:DirParam} <: AbstractVector{T}

length{T,_,D<:Forward}(v::AbstractNodePtrView{T,_,D}) = length(v.n.forward)
length{T,_,D<:Reverse}(v::AbstractNodePtrView{T,_,D}) = length(v.n.reverse)
length{T,_,D<:Both}(v::AbstractNodePtrView{T,_,D})    = length(v.n.reverse) + length(v.n.forward)

size(v::AbstractNodePtrView) = (length(v),)


"""
    NodeIDView{N,1}

A view on ids of node `n`'s neighbors. Parameter `D` specifies which of its
fields with `NodePtr` vectors to use:
  * out-neighbors in a directed graph (`D<:Forward`) - `forward` field
  * in-neighbors in a directed graph (`D<:Reverse`) - `reverse` field
  * out-neighbors in a reversed directed graph (`D<:Reverse`) - `reverse` field
  * in-neighbors in a reversed directed graph (`D<:Forward`) - `forward` field
  * all neighbors in any graph (`D<:Both`) - both fields
"""
immutable NodeIDView{N,_,D,E} <: AbstractNodePtrView{N,_,D}
    n :: Node{N,E}
end

NodeIDView{N,E,D}(n::Node{N,E}, ::Type{D}) = NodeIDView{N,1,D,E}(n)

@inline getindex{N,_,D<:Forward}(p::NodeIDView{N,_,D}, i::Integer) = p.n.forward[i].node
@inline getindex{N,_,D<:Reverse}(p::NodeIDView{N,_,D}, i::Integer) = p.n.reverse[i].node
@inline getindex{N,_,D<:Both}(p::NodeIDView{N,_,D}, i::Integer) = begin
    @_propagate_inbounds_meta
    l = length(p.n.reverse)
    n = i <= l ? p.n.reverse[i] : p.n.forward[i-l]
    return n.node
end


"""
    EdgeIDView{E,1}

Same as `NodeIDView`, but for edge ids.
"""
immutable EdgeIDView{E,_,D,N} <: AbstractNodePtrView{E,_,D}
    n :: Node{N,E}
end

EdgeIDView{N,E,D}(n::Node{N,E}, ::Type{D}) = EdgeIDView{E,1,D,N}(n)

@inline getindex{E,_,D<:Forward}(p::EdgeIDView{E,_,D}, i::Integer) = p.n.forward[i].id
@inline getindex{E,_,D<:Reverse}(p::EdgeIDView{E,_,D}, i::Integer) = p.n.reverse[i].id
@inline getindex{E,_,D<:Both}(p::EdgeIDView{E,_,D}, i::Integer) = begin
    @_propagate_inbounds_meta
    l = length(p.n.reverse)
    n = i <= l ? p.n.reverse[i] : p.n.forward[i - l]
    return n.id
end


"""
    EdgeView{T<:Edge,1}

`I` is a node identifier type

`D` works exactly like in `NodeIDView` and `EdgeIDView`.
`R` denotes requested direction of edges:
    * `Forward` — out-edges
    * `Reverse` — in-edges
    * `Both` — all adjacent edges
"""
immutable EdgeView{T<:Edge,_,D,R<:DirParam,I,N,E} <: AbstractNodePtrView{T,_,D}
    n  :: Node{N,E}
    id :: I
end

EdgeView{I,N,E,D,R<:Forward}(n::Node{N,E}, i::I, ::Type{D}, ::Type{R}) =
    EdgeView{Edge{I,N,E,D},1,D,R,I,N,E}(n, i)
EdgeView{I,N,E,D,R<:Reverse}(n::Node{N,E}, i::I, ::Type{D}, ::Type{R}) =
    EdgeView{Edge{N,I,E,D},1,D,R,I,N,E}(n, i)
EdgeView{I,N,E,D,R<:Both}(n::Node{N,E}, i::I, ::Type{D}, ::Type{R}) =
    EdgeView{Edge{N,I,E,Both},1,D,R,I,N,E}(n, i)

@inline getindex{T,_,D<:Forward,R}(p::EdgeView{T,_,D,R}, i::Integer) =
    Edge(p.id, p.n.forward[i], D, R)
@inline getindex{T,_,D<:Reverse,R}(p::EdgeView{T,_,D,R}, i::Integer) =
    Edge(p.id, p.n.reverse[i], D, R)
@inline getindex{T,_,D<:Both,R}(p::EdgeView{T,_,D,R}, i::Integer) = begin
    @_propagate_inbounds_meta
    l = length(p.n.reverse)
    n = i <= l ? p.n.reverse[i] : p.n.forward[i - l]
    return Edge(p.id, n, D, R)
end


"""
    AbstractNodePtrRangeView{T,1,D}

Similar to `AbstractNodePtrRangeView`, but creates views onto ranges within
vectors of `NodePtr` elements.
"""
abstract AbstractNodePtrRangeView{T,_,D} <: AbstractNodePtrView{T,_,D}

length{T,_,D<:Forward}(v::AbstractNodePtrRangeView{T,_,D}) = length(v.fwd_range)
length{T,_,D<:Reverse}(v::AbstractNodePtrRangeView{T,_,D}) = length(v.rev_range)
length{T,_,D<:Both}(v::AbstractNodePtrRangeView{T,_,D})    = length(v.rev_range) + length(v.fwd_range)

search_ptr_vector{N,E}(ptrs::Vector{NodePtr{N,E}}, i::Integer) = searchsorted(ptrs, N(i))
search_ptr_vector{N,E}(ptrs::Vector{NodePtr{N,E}}, i::UnitRange) = begin
    start = searchsortedfirst(ptrs, N(i.start))
    stop  = searchsortedlast(ptrs, N(i.stop), start, length(ptrs), Base.Order.ForwardOrdering())
    return start:stop
end

ptr_ranges{D<:Forward}(n::Node, i, ::Type{D}) = (search_ptr_vector(n.forward, i), 0:0)
ptr_ranges{D<:Reverse}(n::Node, i, ::Type{D}) = (0:0, search_ptr_vector(n.reverse, i))
ptr_ranges{D<:Both}(n::Node, i, ::Type{D}) =
    (search_ptr_vector(n.forward, i), search_ptr_vector(n.reverse, i))


"""
    EdgeRangeIDView{E,1}

"""
immutable EdgeRangeIDView{E,_,D,N} <: AbstractNodePtrRangeView{E,_,D}
    n         :: Node{N,E}
    fwd_range :: UnitRange
    rev_range :: UnitRange
end

EdgeRangeIDView{N,E,D}(n::Node{N,E}, i, ::Type{D}) =
    EdgeRangeIDView{E,1,D,N}(n, ptr_ranges(n, i, D)...)

getindex{T,_,D<:Forward}(p::EdgeRangeIDView{T,_,D}, i::Integer) = p.n.forward[p.fwd_range[i]].id
getindex{T,_,D<:Reverse}(p::EdgeRangeIDView{T,_,D}, i::Integer) = p.n.reverse[p.rev_range[i]].id
@inline getindex{T,_,D<:Both}(p::EdgeRangeIDView{T,_,D}, i::Integer) = begin
    @_propagate_inbounds_meta
    l = length(p.rev_range)
    n = i <= l ? p.n.reverse[p.rev_range[i]] : p.n.forward[p.fwd_range[i]]
    return n.id
end


"""
    EdgeRangeView{T<:Edge,1}

`I` is a node identifier type

`D` works exactly like in `NodeIDView` and `EdgeIDView`
`R` denotes requested direction of edges:
    * `Forward` — out-edges
    * `Reverse` — in-edges
    * `Both` — all adjacent edges
"""
immutable EdgeRangeView{T<:Edge,_,D,R<:DirParam,I,N,E} <: AbstractNodePtrRangeView{T,_,D}
    n         :: Node{N,E}
    id        :: I
    fwd_range :: UnitRange
    rev_range :: UnitRange
end

EdgeRangeView{I,N,E,D,R<:Forward}(n::Node{N,E}, i::I, j, ::Type{D}, ::Type{R}) =
    EdgeRangeView{Edge{I,N,E,D},1,D,R,I,N,E}(n, i, ptr_ranges(n, j, D)...)
EdgeRangeView{I,N,E,D,R<:Reverse}(n::Node{N,E}, i::I, j, ::Type{D}, ::Type{R}) =
    EdgeRangeView{Edge{N,I,E,D},1,D,R,I,N,E}(n, i, ptr_ranges(n, j, D)...)
EdgeRangeView{I,N,E,D,R<:Both}(n::Node{N,E}, i::I, j, ::Type{D}, ::Type{R}) =
    EdgeRangeView{Edge{N,I,E,Both},1,D,R,I,N,E}(n, i, ptr_ranges(n, j, D)...)

@inline getindex{T,_,D<:Forward,R}(p::EdgeRangeView{T,_,D,R}, i) =
    Edge(p.id, p.n.forward[p.fwd_range[i]], D, R)
@inline getindex{T,_,D<:Reverse,R}(p::EdgeRangeView{T,_,D,R}, i) =
    Edge(p.id, p.n.reverse[p.rev_range[i]], D, R)
@inline getindex{T,_,D<:Both,R}(p::EdgeRangeView{T,_,D,R}, i) = begin
    @_propagate_inbounds_meta
    l = length(p.rev_range)
    n = i <= l ? p.n.reverse[p.rev_range[i]] : p.n.forward[p.fwd_range[i-l]]
    return Edge(p.id, n, D, R)
end
