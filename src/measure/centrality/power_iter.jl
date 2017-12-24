## Power iteration-based centrality indices ##

"""
    eigenvector(g::Graph[, eps::Real, maxiter::Int])

Compute eigenvector centrality for all nodes in the graph.

The process does not always converge for directed graphs, in which case
the function returns an error. Oftentimes, it is useful to treat the graph
as undirected, `eigenvector(undirected(g))`.

# Arguments
* `g::Graph`: the graph itself.
* `eps::Real=0.0001`: convergence threshold (when score changes for each node
stop exceeding it, the algorithm terminates).
* `maxiter::Int=100`: maximum number of iterations.
"""
function eigenvector(g::Graph, eps::Real=1e-4, maxiter::Int=100)
    @assert(0 < eps <= 0.1, "convergence threshold (eps) should be positive and small")
    n         = nodecount(g)
    score     = fill(0.,     n)
    prevscore = fill(1. / n, n)
    maxdiff   = 1.
    iter      = 0
    @inbounds while maxdiff > eps
        for i = 1:n             # transfer the scores
            score[i] = 0.
            for j = inneighbors(g, i)
                score[i] += prevscore[j]
            end
        end
        λ = 0                   # normalize the scores
        for i = 1:n
            if abs(score[i]) > λ
                λ = score[i]
            end
        end
        if λ == 0
            error("power iteration cannot converge")
            break
        else
            maxdiff = 0.
            for i = 1:n
                score[i] /= λ
                maxdiff = max(maxdiff, abs(score[i] - prevscore[i]))
            end
        end
        iter += 1
        if iter > maxiter && maxdiff > eps
            warn("power iteration did not converge in $maxiter steps, current convergence value is $maxdiff")
            return score
        end
        prevscore, score = score, prevscore
    end
    return prevscore
end


"""
    pagerank(g::Graph[, d::Real, eps::Real])

Compute PageRank scores for all nodes in the graph.

# Arguments
* `g::Graph`: the graph itself.
* `d::Real=0.85`: damping factor (the lesser it is, the bigger proportion
    of scores is redistributed equally between all nodes at each iteration).
* `eps::Real=0.0001`: convergence threshold (when score changes for each node
    stop exceeding it, the algorithm terminates).
"""
function pagerank(g::Graph, d::Real=0.85, eps::Real=1e-4)
    @assert(0 < d < 1,     "damping factor (d) should be between 0 and 1")
    @assert(0 < eps < 0.1, "convergence threshold (eps) should be positive and small")
    n         = nodecount(g)
    score     = fill(0.,     n)
    prevscore = fill(1. / n, n)
    ratio     = [d / outdegree(g, i) for i = 1:n]
    maxdiff   = 1.
    @inbounds while maxdiff > eps
        for i = 1:n                    # transfer the scores
            score[i] = 0.
            for j = inneighbors(g, i)
                score[i] += prevscore[j] * ratio[j]
            end
        end
        leak = (1. - sum(score)) / n    # put the leaked scores back
        maxdiff = 0.
        for i = 1:n
            score[i] += leak
            maxdiff = max(maxdiff, abs(score[i] - prevscore[i]))
        end
        prevscore, score = score, prevscore
    end
    return prevscore
end
