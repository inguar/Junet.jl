## Dyad-based network measures ##

"""
    density(g::Graph)

Graph density. It is a proportion of number of existing edges to the maximum
possible number of edges. Density of an empty graph is 0, and density of
a full graph is 1. Graphs having self-loops and/or multiple edges can have
density larger than 1.
"""
density(g::Graph) = edgecount(g) / maxedgecount(g)

"""
    mutuality(g::Graph)

Number of mutual dyads in the graph. A dyad is mutual if for two nodes
`A` and `B` there are both edge `A → B` and `B → A`.
Edges in undirected graphs always constitute mutual dyads.

# References

Moreno, J.L., and Jennings, H.H. (1938). "Statistics of Social Configurations." Sociometry, 1, 342-374.
"""
function mutuality(g::DirectedGraph)
    count = 0
    for n = g.nodes
        i, j = 1, 1
        while i < length(n.forward) && j < length(n.reverse)
            if n.forward[i] < n.reverse[j]
                i += 1
            elseif n.forward[i] > n.reverse[j]
                j += 1
            else
                count += 1
                i += 1
                j += 1
            end
        end
    end
    return count
end

mutuality(g::UndirectedGraph) = edgecount(g)

"""
    reciprocity(g::Graph)

Graph reciprocity. It is a proportion of mutual dyads to a total
number of non-null dyads.
[Wiki](https://en.wikipedia.org/wiki/Reciprocity_(network_science)#Traditional_definition)
"""
reciprocity(g::Graph) = mutuality(g) / edgecount(g)

"""
    dyadcensus(g::Graph)

Dyad census of the graph. It is a 3-tuple of form (M, A, N), standing for
the numbers of mutual, asymmetric, and null dyads.
"""
function dyadcensus(g::Graph)
    m = mutuality(g)
    return (m, edgecount(g) - m, maxedgecount(g) - edgecount(g))
end

"""
    selfloopcount(g::Graph)

Number of self-loops (edges that start and end at the same node) in the graph.
"""
function selfloopcount(g::Graph)
    cnt = 0
    @inbounds for i = nodes(g)
        @inbounds for j = neighbors(g, i)
            if i == j; cnt += 1; end
        end
    end
    return cnt
end

function selfloopnodes(g::Graph)
    ns = Int[]
    @inbounds for i = nodes(g)
        @inbounds for j = neighbors(g, i)
            if i == j
                push!(ns, i)
                break
            end
        end
    end
    return ns
end
