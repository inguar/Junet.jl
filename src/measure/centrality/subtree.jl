function subtree_size(g::DirectedGraph, n::Integer,
                      visited=falses(nodecount(g)),
                      stack=zeros(Int, nodecount(g)))
    first, last = 1, 2
    stack[first] = n
    visited[n] = true
    @inbounds while first < last
        i = stack[first]
        @inbounds for j = inneighbors(g, i)
            if !visited[j]
                stack[last] = Int(j)
                last += 1
                visited[j] = true
            end
        end
        first += 1
    end
    @inbounds for i = 1:last - 1
        visited[stack[i]] = false
    end
    return first - 2
end

"""
    subtree_size(g::DirectedGraph[, n::Integer])

Number of nodes that can reach node `n` following directed links.
If `n` not provided, computes this number for each node.
"""
function subtree_size(g::DirectedGraph)
    vis = falses(nodecount(g))
    stack = zeros(Int, nodecount(g))
    res = zeros(Float64, nodecount(g))
    @inbounds for i = nodes(g)
        res[i] = Float64(subtree_size(g, i, vis, stack))
    end
    return res
end