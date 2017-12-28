## Efficient implementation of node and edge attributes ##

length(a::AbstractAttribute) = a.getlen()
size(a::AbstractAttribute) = (a.getlen(),)


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

getindex(x::SparseAttribute, i::Integer) = get(x.data, i, x.default)
function setindex!(x::SparseAttribute{T}, v, i::Integer) where {T}
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
DenseAttribute(x::Vector{T}, f::F) where {T,F<:Function} = DenseAttribute(defval(T), x, f)
DenseAttribute(x::AbstractAttribute{T,N,F}) where {T,N,F<:Function} =
    DenseAttribute{T,N,F}(x.default, collect(x), x.getlen)

getindex(x::DenseAttribute, i::Integer) = checkbounds(Bool, x, i) ? x.data[i] : x.default
function setindex!(x::DenseAttribute{T}, v::T, i::Integer) where {T}
    l = x.getlen()
    if i <= l
        while length(x) < i
            push!(x.data, x.default)
        end
    else
        error("trying to set value out of bounds")
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


# """
#     attribute(x)

# Create an appropriate attribute instance depending on the type of x.
# """
# attribute(a::AbstractAttribute) = a
# attribute(v::Vector) = length(v) == 1 ? DenseAttribute(v[1]) : DenseAttribute(v)
# attribute(x) = ConstantAttribute(x)
