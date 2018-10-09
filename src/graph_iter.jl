## Graph iterators ##

get_node_id(::Integer, ptr::NodePtr, ::Bool, ::Type{R}) where {R<:DirParam} =
        (@_inline_meta; ptr.node)
get_edge_id(::Integer, ptr::NodePtr, ::Bool, ::Type{R}) where {R<:DirParam} =
        (@_inline_meta; ptr.id)
get_edge(n::Integer, ptr::NodePtr, isdir::Bool, ::Type{Forward}) =
        (@_inline_meta; Edge(n, ptr.node, ptr.id, isdir))
get_edge(n::Integer, ptr::NodePtr, isdir::Bool, ::Type{Reverse}) =
        (@_inline_meta; Edge(ptr.node, n, ptr.id, isdir))

# TODO: refactor Edge system for efficiency
# TODO: 1. create edges with native types (N,E)
# TODO: 2. add getters source() and target() that convert ids to Int
# TODO: 3. throughout Junet, convert e.source to source(e)


"""
    PtrView(g::Graph, i::Integer, ::Type{R}, fun::F)

A view used to browse through `NodePtr` objects associated with node `i`.
`R` shows the requested direction: `Forward` for outgoing ones, `Reverse`—for incoming,
and `Both` for both. Each `NodePtr` is then fed into the function `fun`, for which
there are 3 choices: `get_node_id`, `get_edge_id`, and `get_edge`.

# Examples

To get outgoing edges of node `1`, run:
```julia
    PtrView(g, 1, Forward, get_edge)
```

Similarly, for in-neighbors:
```julia
    PtrView(g, 1, Reverse, get_node_id)
```

# Type parameters

This view class is very flexible and can be used to produce 27 different kinds of views.
Under the hood, it uses multiple dispatch to construct and run the correct methods.
It relies on a number of parameters:

* `O` — shows which vector of `NodePtrs` associated with a node to use
* `D` — same as `D` in `Graph`, signifies directedness
* `R` — same as `R` passed in the constructor
* `F` — type of function used to transform the elements
* `N` and `E` are the graph's node and edge ID types

"""
struct PtrView{O<:DirParam,D<:DirParam,R<:DirParam,F,N,E}
    src  :: N
    node :: Node{N,E}
    fun  :: F
end

# const NodeIDView = PtrView{O,D,R,<:typeof(get_node_id)} where {O,D,R}
# const EdgeIDView = PtrView{O,D,R,<:typeof(get_edge_id)} where {O,D,R}
# const EdgeView = PtrView{O,D,R,<:typeof(get_edge_id)} where {O,D,R}

PtrView(g::Graph{N,E,D}, i::Integer, ::Type{R}, fun::F) where {N,E,D,R<:DirParam,F<:Function} =
            PtrView{dir_xor(D,R),D,R,F,N,E}(N(i), g.nodes[i], fun)

eltype(::Type{PtrView{O,D,R,F,N,E}}) where {O,D,R,F<:typeof(get_node_id),N,E} = N
eltype(::Type{PtrView{O,D,R,F,N,E}}) where {O,D,R,F<:typeof(get_edge_id),N,E} = E
eltype(::Type{PtrView{O,D,R,F,N,E}}) where {O,D,R,F<:typeof(get_edge),N,E} = Edge{N,E}
IteratorEltype(::Type{PtrView}) = HasEltype()

length(x::PtrView{O}) where {O<:Forward} = length(x.node.forward)
length(x::PtrView{O}) where {O<:Reverse} = length(x.node.reverse)
length(x::PtrView{O}) where {O<:Both} = length(x.node.forward) + length(x.node.reverse)
IteratorSize(::Type{PtrView}) = HasLength()

function iterate(x::PtrView, i=1)
    @_inline_meta
    if i < length(x)
        return x[i], i + 1
    end
end

getindex(x::PtrView{O,D,R}, i::Integer) where {O<:Forward,D,R} =
    (@_inline_meta; @_propagate_inbounds_meta; x.fun(x.src, x.node.forward[i], true, R))
getindex(x::PtrView{O,D,R}, i::Integer) where {O<:Reverse,D,R} =
    (@_inline_meta; @_propagate_inbounds_meta; x.fun(x.src, x.node.reverse[i], true, R))
function getindex(x::PtrView{O,D,R}, i::Integer) where {O<:Both,D<:Both,R}  # R <: Forward | Both
    @_inline_meta; @_propagate_inbounds_meta
    let l = length(x.node.reverse)
        if i <= l
            return x.fun(x.src, x.node.reverse[i], false, Forward)
        else
            return x.fun(x.src, x.node.forward[i - l], false, Forward)
        end
    end
end
function getindex(x::PtrView{O,D,R}, i::Integer) where {O<:Both,D<:Both,R<:Reverse}  # D <: Both
    @_inline_meta; @_propagate_inbounds_meta
    let l = length(x.node.reverse)
        if i <= l
            return x.fun(x.src, x.node.reverse[i], false, Reverse)
        else
            return x.fun(x.src, x.node.forward[i - l], false, Reverse)
        end
    end
end
function getindex(x::PtrView{O,D}, i::Integer) where {O<:Both,D<:Forward}  # R <: Both
    @_inline_meta; @_propagate_inbounds_meta
    @inbounds let l = length(x.node.reverse)
        if i <= l
            return x.fun(x.src, x.node.reverse[i], true, Reverse)
        else
            return x.fun(x.src, x.node.forward[i - l], true, Forward)
        end
    end
end
function getindex(x::PtrView{O,D}, i::Integer) where {O<:Both,D<:Reverse}  # R <: Both
    @_inline_meta; @_propagate_inbounds_meta
    let l = length(x.node.forward)
        if i <= l
            return x.fun(x.src, x.node.forward[i], true, Reverse)
        else
            return x.fun(x.src, x.node.reverse[i - l], true, Forward)
        end
    end
end

# TODO: implement custom bounds checking / strip extra bounds checks
# TODO: make it a child of AbstractArray, overload the necessary methods to make it work properly
# TODO: play around with lambdas or parent-scope counter to shake off the extra comparisons


"""
    EdgeIter(g::Graph)

Iterator over all edges in the graph.

Under the hood, it uses a 3-tuple of type {N, Int, Bool} to hold the state
during the iteration.
"""
struct EdgeIter{N,E,D}
    graph :: Graph{N,E,D}
end

eltype(::Type{EdgeIter{N,E,D}}) where {N,E,D} = Edge{N,E}
IteratorEltype(::Type{EdgeIter}) = HasEltype()

length(x::EdgeIter) = edgecount(x.graph)
IteratorSize(::Type{EdgeIter}) = HasLength()

function iterate(x::EdgeIter{N,E,D}, state=(1, 1)) where {N,E,D}
    node_ind, ptr_ind = state
    @inbounds while true
        ptrs = fwd_ptrs(x.graph.nodes[node_ind], D)
        if ptr_ind <= length(ptrs)
            edge = get_edge(N(node_ind), ptrs[ptr_ind], D<:Directed, Forward)
            return edge, (node_ind, ptr_ind + 1)
        else
            node_ind += 1
            if node_ind > nodecount(x.graph)
                return nothing
            end
            ptr_ind = 1
        end
    end
end
