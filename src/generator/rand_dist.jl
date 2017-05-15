# Miscellaneous code to generate random outcomes with predefined discrete
# probability distribution

# TODO: move this over to a separate module

import Base: push!, pop!, getindex, rand

type DistributionPicker{T<:Integer}
    weights :: Vector{T}
end

function push!{T}(d::DistributionPicker{T}, x::T)
    if length(d.weights) == 0
        push!(d.weights, x)
    else
        root = length(d.weights) >> 1 + 1
        push!(d.weights, d.weights[root])
        push!(d.weights, x)
        while root != 0
            d.weights[root] += x
            root >>= 1
        end
    end
end

function pop!(d::DistributionPicker)
    x = pop!(d.weights)
    pop!(d.weights)
    root = length(d.weights) >> 1
    while root != 0
        d.weights[root] -= x
        root >>= 1
    end
    return x
end

function findindex(d::DistributionPicker, i::Integer)
    j = i * 2 - 1
    while true
        j_ = j << 1
        if j_ <= length(d.weights)
            j = j_
        else
            break
        end
    end
    return j
end

function inc_index!(d::DistributionPicker, i::Integer)
    root = findindex(d, i)
    while root != 0
        d.weights[root] += 1
        root >>= 1
    end
end

function rand(d::DistributionPicker, pair=false)
    x = rand(1:d.weights[1])
    i = 1       # current node index
    j = 1       # index in original order
    while true
        i_ = i << 1
        i_ > length(d.weights) && break
        if x <= d.weights[i_]
            i = i_
        else
            j = i + 1
            i = i_ + 1
            x -= d.weights[i_]
        end
    end
    return pair ? (j, x) : j
end
