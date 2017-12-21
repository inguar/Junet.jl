## Compute the clustering coefficient ##

maxtrianglecount(g::DirectedGraph, k::Integer) = k * (k - 1)
maxtrianglecount(g::UndirectedGraph, k::Integer) = div(k * (k - 1), 2)


# Adapted from graph-tool with improvements
function triangles(g::Graph, n::Integer, mark::Vector)
    @inbounds for i = neighbors(g, n)
        i == n && continue
        mark[i] = true
    end
    count = 0
    @inbounds for i = neighbors(g, n)
        i == n && continue
        for j = neighbors(g, i)
            j == n && continue
            if mark[j]; count += 1; end
        end
    end
    @inbounds for i = neighbors(g, n)
        mark[i] = false
    end
    return count
end


function dirtriangles(g::DirectedGraph, n::Integer, mark::Vector)
    @inbounds for i = neighbors(g, n)
        i == n && continue
        mark[i] = true
    end
    count = 0
    @inbounds for i = outneighbors(g, n)
        i == n && continue
        for j = outneighbors(g, i)
            j == n && continue
            if mark[j]; count += 1; end
        end
    end
    @inbounds for i = neighbors(g, n)
        mark[i] = false
    end
    return count
end

function _trackcycles!(g::DirectedGraph, n::Integer, mark::Vector)
    @inbounds for i = inneighbors(g, n)
        mark[i] = -1
    end
    @inbounds for i = outneighbors(g, n)
        mark[i] = 1
    end
    count = 0
    @inbounds for i = outneighbors(g, n)
        i == n && continue
        for j = outneighbors(g, i)
            j == n && continue
            if mark[j] == -1; count += 1; end
        end
    end
    @inbounds for i = neighbors(g, n)
        mark[i] = 0
    end
    return count
end

function cycle3count(g::Graph)
    n    = nodecount(g)
    mark = fill(0, n)
    tri, tot = 0, 0
    @inbounds for i = nodes(g)
        d = degree(g, i)
        if d > 1
            tri += _trackcycles!(g, i, mark)
        end
        tot += maxtrianglecount(g, d)
    end
    return tri
end


function clustering(g::Graph)
    n    = nodecount(g)
    mark = fill(false, n)
    tri, tot = 0, 0
    @inbounds for i = nodes(g)
        d = degree(g, i)
        if d > 1
            tri += dirtriangles(g, i, mark)
        end
        tot += maxtrianglecount(g, d)
    end
    return tri * 4. / tot
end
