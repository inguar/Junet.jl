function branch!(g::Graph, root, i, l, d)
    for j = 1:l
        addnode!(g)
        k = nodecount(g)
        addedge!(g, k, root)
        if i < d
            branch!(g, k, i+1, l, d)
        end
    end
end

function tree(l::Integer, d::Integer; params...)
    g = Graph(;params...)
    addnode!(g)
    branch!(g, 1, 1, l, d)
    g
end
