"""
    DiscreteSampler{T}

Efficient ``O(\\log_2 n)`` sampler from discrete probability distributions.
It is based on a custom binary heap with the following properties:
* each value is proportional to the probability of corresponding element,
* each root has the sum of its children's values,
  ``w_i = w_{2i} + w_{2i + 1}``,
* real indices of elements (leaves) can be found using `findindex`.
"""
struct DiscreteSampler{T}
    values :: Vector{T}
end

function push!(d::DiscreteSampler{T}, value) where T
    x = T(value)
    if length(d.values) == 0
        push!(d.values, x)
    else
        root = length(d.values) >> 1 + 1
        push!(d.values, d.values[root])
        push!(d.values, x)
        while root != 0
            d.values[root] += x
            root >>= 1
        end
    end
end

function pop!(d::DiscreteSampler)
    x = pop!(d.values)
    pop!(d.values)
    root = length(d.values) >> 1
    while root != 0
        d.values[root] -= x
        root >>= 1
    end
    return x
end

function findindex(d::DiscreteSampler, i::Integer)
    j = i * 2 - 1
    while true
        j_ = j << 1
        if j_ <= length(d.values)
            j = j_
        else
            break
        end
    end
    return j
end

function inc_index!(d::DiscreteSampler{T}, i::Integer) where T
    root = findindex(d, i)
    while root != 0
        d.values[root] += one(T)
        root >>= 1
    end
end

function dec_index!(d::DiscreteSampler{T}, i::Integer) where T
    root = findindex(d, i)
    while root != 0
        d.values[root] -= one(T)
        root >>= 1
    end
end

# Could not be `rand` to avoid clash with `Random` module, which had
# too many functions unneeded by `Junet` to build on.
function randd(d::DiscreteSampler, return_residual=false)
    x = rand(1:d.values[1])
    i = 1       # current node index
    j = 1       # index in original order
    while true
        i_ = i << 1
        i_ > length(d.values) && break
        if x <= d.values[i_]
            i = i_
        else
            j = i + 1
            i = i_ + 1
            x -= d.values[i_]
        end
    end
    return return_residual ? (j, x) : j
end
