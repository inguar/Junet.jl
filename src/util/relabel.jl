## Relabel vector elements to 1:n ##

function relabel(label::Vector{T}) where {T}
    label_ = similar(label, Int)
    dict = Dict{T,Int}()
    for (i, l) = enumerate(label)
        if !haskey(dict, l)
            dict[l] = length(dict) + 1
        end
        label_[i] = dict[l]
    end
    return label_
end
