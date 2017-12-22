## Closeness and harmonic centrality ##

# TODO: verify this against a correct implementation of Dijkstra's algorithm
# TODO: set up array reuse for `closeness` and `harmonic_centrality`

function distances(g::Graph, n::Integer,
                   dists=fill(typemax(Int), nodecount(g)),
                   visited=falses(nodecount(g)),
                   stack=zeros(Int, nodecount(g)))
    head, tail = 1, 2
    dists[n] = 0
    stack[head] = n
    visited[n] = true
    @inbounds while head < tail
        i = stack[head]
        @inbounds for j = neighbors(g, i)
            if !visited[j]
                if dists[j] > dists[i] + 1
                    dists[j] = dists[i] + 1
                end
                stack[tail] = Int(j)
                tail += 1
                visited[j] = true
            end
        end
        head += 1
    end
    @inbounds for i = 1:tail - 1
        visited[stack[i]] = false
    end
    return dists
end

"""
    closeness(g::Graph[, v::Integer])

Closeness centrality of node `v`.

# References
[Tore Opsahl's blog](https://toreopsahl.com/2010/03/20/closeness-centrality-in-networks-with-disconnected-components/)
"""
function closeness(g::Graph, v::Integer)
    n, s = 0, 0
    for d = distances(g, v)
        if d < typemax(Int)
            n += 1
            s += d
        end
    end
    return n / s
end

closeness(g::Graph) = [closeness(g, i) for i = nodes(g)]

"""
    harmonic_centrality(g::Graph[, v::Integer])

Harmonic centrality for node `v`, a better-behaved version of closeness centrality

# References
Rochat, Yannick. 2009. “Closeness Centrality Extended to Unconnected Graphs:
The Harmonic Centrality Index.” In ASNA.

[Tore Opsahl's blog](https://toreopsahl.com/2010/03/20/closeness-centrality-in-networks-with-disconnected-components/)
"""
function harmonic_centrality(g::Graph, v::Integer)
    s = 0.
    for d = distances(g, v)
        if 0 < d < typemax(Int)
            s += 1 / d
        end
    end
    return s
end

harmonic_centrality(g::Graph) = [harmonic_centrality(g, i) for i = nodes(g)]
