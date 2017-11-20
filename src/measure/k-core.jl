## K-core decomposition ##

function _binsortperm(deg::Vector, n::Integer)
    vert = Array{Int}(n)    # `vert` is the order of vertices
    pos  = Array{Int}(n)    # `pos` is a reverse index to `vert`
    md   = maximum(deg)
    bin  = fill(0, 1 + md)  # `bin` captures offsets for each degree
    @inbounds for i = deg
        bin[1 + i] += 1
    end
    s = 1
    @inbounds for i = 1:(1 + md)
        t = bin[i]
        bin[i] = s
        s += t
    end
    @inbounds for i = 1:n
        pos[i] = bin[1 + deg[i]]
        vert[pos[i]] = i
        bin[1 + deg[i]] += 1
    end
    return vert, pos, bin
end

"""
    kcores(g::Graph)

Compute k-core secomposition of a graph.
Returns a vector with maximum core number for each node.

Implementation based on Vladimir Batagelj and Matjaž Zaveršnik's
"An O(m) Algorithm for Cores Decomposition of Networks"
[link](http://vlado.fmf.uni-lj.si/pub/networks/doc/cores/cores.pdf)
"""
function kcores(g::Graph)
    n   = nodecount(g)
    deg = degree(g)
    vert, pos, bin = _binsortperm(deg, n)
    @inbounds for i = vert
        for j = neighbors(g, i)
            if deg[j] > deg[i]
                dj = deg[j]
                pj = pos[j]
                pk = bin[dj]
                k = vert[pk]
                if k != j
                    pos[j] = pk
                    pos[k] = pj
                    vert[pj] = k
                    vert[pk] = j
                end
                bin[dj] += 1
                deg[j]  -= 1
            end
        end
    end
    return deg
end
