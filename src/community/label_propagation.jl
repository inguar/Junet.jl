## Label propagation algorithm for detecting communities ##

function _count_neighbor_labels(g::Graph, label::Vector{Int}, n::Integer)
    count = Dict{Int,Int}()
    for i = neighbors(g, n)
        l = label[i]
        count[l] = get(count, l, 0) + 1
    end
    return count
end

# TODO: move to "utils" and use in component functions
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


"""
    label_propagation(g::Graph)

A simple implementation of the label propagation algorithm.

# References

Raghavan, Usha Nandini, Réka Albert, and Soundar Kumara.
“Near Linear Time Algorithm to Detect Community Structures in Large-Scale Networks.”
Physical Review E 76, no. 3 (2007).
"""
function label_propagation(g::Graph)
    label = collect(nodes(g))
    finished = false
    while !finished
        order = shuffle(nodes(g))
        # Assign new labels
        for i = order
            count = _count_neighbor_labels(g, label, i)
            maxlabel, maxcount = 0, 0
            for l = keys(count)
                if count[l] > maxcount || count[l] == maxcount && order[l] < order[maxlabel]
                    maxlabel = l
                    maxcount = count[l]
                end
            end
            label[i] = maxlabel
        end
        # Check if labels don't need to be changed
        finished = true
        for i = nodes(g)
            count = _count_neighbor_labels(g, label, i)
            lcount = get(count, label[i], 0)
            if any(c > lcount for c = values(count))
                finished = false
                break
            end
        end
    end
    return relabel(label)
end