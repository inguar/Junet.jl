## Efficient implementation of node and edge attributes ##

length(x::AbstractAttribute) = x.getlen()
lastindex(x::AbstractAttribute) = x.getlen()
size(x::AbstractAttribute) = (x.getlen(),)


"""
    ConstantAttribute{T}

Attribute always returning the same (default) value.
"""
mutable struct ConstantAttribute{T,N,F} <: AbstractAttribute{T,N,F}
    default :: T
    getlen  :: F
end

ConstantAttribute(d::T, f::F) where {T,F<:Function} = ConstantAttribute{T,1,F}(d, f)

getindex(x::ConstantAttribute, ::Integer) = x.default
setindex!(::ConstantAttribute, ::Any, ::Integer) = 
    error("constant attributes don't support element assignments")
setdefault!(x::ConstantAttribute{T}, d::T) where {T} = x.default = d
deleteat!(::ConstantAttribute, ::Integer) = nothing


"""
    SparseAttribute{T}

Attribute having most of its elements equal to the default value.
Under the hood uses `Dict` to store non-default elements.
"""
mutable struct SparseAttribute{T,N,F} <: AbstractAttribute{T,N,F}
    default :: T
    data    :: Dict{Int,T}
    getlen  :: F
end

SparseAttribute(d::T, f::F) where {T,F<:Function} = SparseAttribute{T,1,F}(d, Dict{Int,T}(), f)
SparseAttribute(x::ConstantAttribute{T,N,F}) where {T,N,F} =
    SparseAttribute{T,N,F}(x.default, Dict{Int,T}(), x.getlen)
density(x::SparseAttribute) = length(x.data) / x.getlen()

getindex(x::SparseAttribute, i::Integer) = get(x.data, i, x.default)
function setindex!(x::SparseAttribute{T}, v, i::Integer) where {T}
    @boundscheck checkbounds(1:x.getlen(), i)
    if v != x.default
        x.data[i] = v
    else
        delete!(x.data, i)
    end
end
setdefault!(x::SparseAttribute{T}, d::T) where {T} = x.default = d
deleteat!(x::SparseAttribute, i::Integer) = delete!(x.data, i)


"""
    DenseAttribute{T}

Attribute with most of its values being unique. Under the hood, uses `Vector`
to store all elements.
"""
mutable struct DenseAttribute{T,N,F} <: AbstractAttribute{T,N,F}
    default :: T
    data    :: Vector{T}
    getlen  :: F
end

DenseAttribute(d::T, f::F) where {T,F<:Function} = DenseAttribute{T,1,F}(d, T[], f)
DenseAttribute(d::T, x::Vector{T}, f::F) where {T,F<:Function} =
    DenseAttribute{T,1,F}(d, x, f)
DenseAttribute(x::AbstractVector{T}, f::F) where {T,F<:Function} =
    DenseAttribute(defval(T), collect(x), f)
DenseAttribute(x::AbstractAttribute{T,N,F}) where {T,N,F<:Function} =
    DenseAttribute{T,N,F}(x.default, collect(x), x.getlen)

getindex(x::DenseAttribute, i::Integer) = checkbounds(Bool, x.data, i) ? x.data[i] : x.default
function setindex!(x::DenseAttribute{T}, v::T, i::Integer) where {T}
    @boundscheck checkbounds(1:x.getlen(), i)
    while length(x.data) < i
        push!(x.data, x.default)
    end
    x.data[i] = v
end
function setdefault!(x::DenseAttribute{T}, d::T) where {T}
    for (i, v) = enumerate(x.data)
        if v == x.default
            x.data[i] = d
        end
    end
    x.default = d
end
deleteat!(x::DenseAttribute, i) = checkbounds(Bool, x, i) && deleteat!(x.data[i], i)


"""
    attribute(x, f)

Create an appropriate attribute instance depending on the type of `x`.
Anonymous function `f()` should return the length.
"""
attribute(x::AbstractAttribute, f::Function) = x  # TODO: use this to reassign attributes to different graphs
attribute(x::AbstractArray, f::Function) = DenseAttribute(x, f)
attribute(x, f::Function) = ConstantAttribute(x, f)

nodeattr(g::Graph, v) = attribute(v, ()->nodecount(g))
edgeattr(g::Graph, v) = attribute(v, ()->edgecount(g))

# TODO: 1. get rid of setindex!(d::AttributeDict, v, s::Symbol, i) in graph_operations.jl
# TODO: 2. introduce an `AttributeBuilder` class
# TODO: 3. find most common value on at least 100 fist ones and do an informed conversion
# TODO: 4. create a method that substantiates attributes from all `AttributeBuilder`s
# TODO: 5. replace currrent attribute assignment in all IO files
