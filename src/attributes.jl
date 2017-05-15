# Efficient container types for node and edge attributes.

import Base: length, size, sizehint!, getindex, setindex!, delete!,
             eachindex, similar

"""
    null(::Type{T})

Get an empty (null) value for a type. Works like `zero()`, but for more types.
"""
null{T<:Number}(::Type{T}) = zero(T)
null(::Type{String}) = ""
null(::Type{Char}) = '\0'
null(::Type{Void}) = nothing


"""
    AbstractAttribute{T}

Abstract parent for graph attribute types. They behave like `Vector`s.
"""
abstract AbstractAttribute{T} <: AbstractVector{T}

length(a::AbstractAttribute) = a.length
size(a::AbstractAttribute) = (a.length,)
sizehint!(a::AbstractAttribute, sz::Integer) = a.length = sz

# Redefinition of `eachindex` and `similar` is needed for efficient duplication
# of `Attribute` instances. Index 0 serves as proxy for default values.
eachindex(a::AbstractAttribute) = 0:length(a)

typealias AttributeDict Dict{Symbol, AbstractAttribute}


#=
Don't grow the attribute until assignment somewhere out of range

Update the length both on writes **and** reads though, so if the user wants to
serialize it, everything works
=#

"""
    ConstantAttribute{T}

Attribute always returning a default value. Extremely memory efficient, does
no bounds checks.
"""
type ConstantAttribute{T} <: AbstractAttribute{T}
    default :: T
    length  :: Int
end

ConstantAttribute(default, length=0) = ConstantAttribute(default, length)
getindex(c::ConstantAttribute, ::Integer) = c.default
setindex!{T}(c::ConstantAttribute{T}, x::T, i::Integer) =
    if i == 0
        c.default = x
    else
        error("Constant attributes don't support element assignments")
    end
delete!(c::ConstantAttribute, i::Integer) = nothing
eachindex(c::ConstantAttribute) = [0]
similar{T}(c::ConstantAttribute, ::Type{T}) = ConstantAttribute{T}(T(c.default), c.length)


"""
    SparseAttribute{T,I}

Attribute having most of its values equal to the default one. Under the hood,
uses `Dict` to store non-default elements.

`T` is its element type, `I` is a preferred indexing type.
"""
type SparseAttribute{T,_,I} <: AbstractAttribute{T}
    data    :: Dict{I,T}
    default :: T
    length  :: Int
end

SparseAttribute{T}(default::T, idtype=Int) = SparseAttribute{T,1,idtype}(Dict{idtype,T}(), default, 0)
SparseAttribute{T}(c::ConstantAttribute{T}, idtype=Int) =
    SparseAttribute{T,1,idtype}(Dict{idtype,T}(), c.default, c.length)

getindex(s::SparseAttribute, i::Integer) = get(s.data, i, s.default)
setindex!{T}(s::SparseAttribute{T}, x, i::Integer) =
    if i == 0
        s.default = x
    else
        if x != s.default; s.data[i] = x else delete!(s.data, i) end
    end

delete!(s::SparseAttribute, i::Integer) = delete!(s.data, i)

eachindex{T,I}(s::SparseAttribute{T,I}) = [zero(I), keys(s.data)...]

function similar{T,I,T_}(s::SparseAttribute{T,I}, ::Type{T_})
    d = Dict{I,T_}()
    for i = keys(s.data)
        d[i] = T_(s.data[i])
    end
    SparseAttribute{T_,I}(d, T_(s.default), s.length)
end


"""
    DenseAttribute{T}

Attribute with most of its values being unique. Under the hood, uses `Vector`
to store all elements.
"""
type DenseAttribute{T} <: AbstractAttribute{T}
    data    :: Vector{T}
    default :: T
    length  :: Int
end

DenseAttribute{T}(default::T, length=0) = DenseAttribute(T[], default, 0)
DenseAttribute{T}(v::Vector{T}, default::T) = DenseAttribute(v, default, length(v))
DenseAttribute{T}(v::Vector{T}) = DenseAttribute(v, null(T), length(v))
DenseAttribute(s::SparseAttribute) = DenseAttribute(collect(s), s.default, s.length)

# FIXME index 0 not supported yet
getindex(d::DenseAttribute, i::Integer) = d.data[i]
setindex!{T}(d::DenseAttribute{T}, x::T, i::Integer) = d.data[i] = x
delete!(d::DenseAttribute, i::Integer) = d.data[i] = d.default

function sizehint!(d::DenseAttribute, sz::Integer)
    if length(d.data) < sz
        while true
            push!(d.data, d.default)
            length(d.data) == sz && break
        end
    elseif length(d.data) > sz
        while true
            pop!(d.data)
            length(d.data) == sz && break
        end
    end
    d.length = sz
end

similar{T,T_}(d::DenseAttribute{T}, ::Type{T_}) =
    DenseAttribute{T_}([T_(i) for i = d.data], T_(d.default), d.length)


"""
    VectorAttribute{T}

Attribute with its values being mostly unique vectors of the same length.
Uses `Matrix` under the hood.
"""
type VectorAttribute{T} <: AbstractAttribute{T}
    data    :: Matrix{T}
    default :: Vector{T}
    length  :: Int
end

VectorAttribute{T}(m::Matrix{T}) = VectorAttribute()

getindex(v::VectorAttribute, i::Integer) = v.data[i,:]
setindex!(v::VectorAttribute, x::VecOrMat, i::Integer) = v.data[i,:] = x
delete!(v::VectorAttribute, i::Integer) = v.data[i,:] = v.default

# TODO: finish implementing the methods for this type

"""
    attribute(x)

Create an appropriate attribute instance depending on the type of x.
"""
attribute(a::AbstractAttribute) = a
attribute(v::Vector) = length(v) == 1 ? DenseAttribute(v[1]) : DenseAttribute(v)
attribute(x) = ConstantAttribute(x)