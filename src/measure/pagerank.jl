"""
    pagerank(g::Graph)

Compute PageRank for all nodes in the graph.

Optionally, you can set the following parameters:
  - d, default 0.85   — damping factor (the lesser it is, the more weight
    is redistributed equally between the nodes at each iteration)
  - ϵ, default 0.0001 — convergence threshold (when weight changes for each node
    stop exceeding it, the algorithm terminates).
"""
function pagerank(g::Graph, d=0.85, ϵ=1e-4)
    @assert(0 < d < 1,   "Value of `d` should be between 0 and 1")
    @assert(0 < ϵ < 0.1, "Value of `ϵ` should be positive and small")
    n        = nodecount(g)
    rank     = fill(0.,     n)
    prevrank = fill(1. / n, n)
    ratio    = [d / outdegree(g, i) for i = 1:n]
    maxdiff  = 1.
    @inbounds while maxdiff > ϵ
        for i = 1:n                    # transfer the weights
            rank[i] = 0.
            for j = inneighbors(g, i)
                rank[i] += prevrank[j] * ratio[j]
            end
        end
        leak = (1. - sum(rank)) / n    # put the leaked weights back
        maxdiff = 0.
        for i = 1:n
            rank[i] += leak
            maxdiff = max(maxdiff, abs(rank[i] - prevrank[i]))
        end
        prevrank, rank = rank, prevrank
    end
    return prevrank
end


# for Julia 0.5

# function pagerank(g::Graph, d=0.85, ϵ=1e-4)
#     @assert(0 < d < 1,   "Value of `d` should be between 0 and 1")
#     @assert(0 < ϵ < 0.1, "Value of `ϵ` should be positive and small")
#     n        = nodecount(g)
#     rank     = fill(0.,     n)
#     prevrank = fill(1. / n, n)
#     ratio    = [d / outdegree(g, i) for i = 1:n]
#     done     = false
#     @inbounds while !done
#         for i = 1:n                    # transfer the weights
#             for j = inneighbors(g, i)
#                 rank[i] += prevrank[j] * ratio[j]
#             end
#         end
#         loss = (1. - sum(rank)) / n    # put the lost weight back
#         for i = 1:n
#             rank[i] += loss
#         end
#         done = true                    # check convergence
#         for i = 1:n
#             if abs(rank[i] - prevrank[i]) > ϵ
#                 done = false
#                 break
#             end
#         end
#         prevrank, rank = rank, prevrank
#         fill!(rank, 0.)
#     end
#     return prevrank
# end
