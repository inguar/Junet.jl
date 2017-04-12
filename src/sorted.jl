"""
    insertsorted!(vec, val)

Insert `val` into a sorted vector `vec`.
"""
function insertsorted!{T}(vec::Vector{T}, val::T)
    i = searchsortedlast(vec, val) + 1
    insert!(vec, i, val)
end


"""
    insertsortedone!(vec, val)

Insert `val` into a sorted vector `vec` if it is not there already.
Returns `true` or `false` depending on whether it was inserted.
"""
function insertsortedone!{T}(vec::Vector{T}, val::T)
    i = seeklast(vec, val)
    @inbounds if i == 0 || vec[i] != val
        i += 1
        _growat!(vec, i, 1)
        vec[i] = val
        return true
    else
        return false
    end
end
