"""
    insertsorted!(vec, val)

Insert `val` into a sorted vector `vec`.
"""
# TODO: repurpose these to work with NodePtr only
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
@inline function delete_ptr!{N,E}(ptrs::Vector{NodePtr{N,E}}, nid::Integer, eid::Integer)
    const n = N(nid)
    const e = E(eid)
    @inbounds for i = searchsorted(ptrs, n)
        if ptrs[i].id == e
            deleteat!(ptrs, i)
            return true
        end
    end
    return false
end

@inline function delete_ptr!{N,E}(ptrs::Vector{NodePtr{N,E}}, nid::Integer)
    const n = N(nid)
    i = searchsortedlast(ptrs, n)
    if i == 0 || ptrs[i] != n
        return false
    else
        deleteat!(ptrs, i)
        return true
    end
end
