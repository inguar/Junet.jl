ensurenode(g::Graph, i::Integer) = addnode!(g, i - nodecount(g));

"""
    load_ngraph(path, directed::Bool, [nodeids::Type])

Loads a graph from [ngraph binary format](https://github.com/anvaka/ngraph.tobinary#linksbin-format).
It requires a folder with 3 files in it: `links.bin`, `labels.json`, and `positions.bin`.
"""
function load_ngraph(path,
                     directed::Bool,
                     nodeids::Type=UInt32)
    g = Graph(directed=directed, nodeids=nodeids)
    # Load the links
    open(joinpath(path, "links.bin")) do f
        src = zero(nodeids)
        for i = reinterpret(nodeids, read(f))
        if i < 0
            src = -i
            ensurenode(g, src)
        else
            ensurenode(g, i)
            addedge!(g, src, i)
        end
    end
    end
    # Load the labels
    open(joinpath(path, "labels.json")) do f
        l = readline(f)[2:end - 1]
        g[:, :label] = [String(strip(i, [' ', '"'])) for i = split(l, ',')]
    end
    # Load the layout
    open(joinpath(path, "positions.bin")) do f
        ints = reinterpret(Int32, read(f))
        g[:, :x] = ints[1:3:end]
        g[:, :y] = ints[2:3:end]
        g[:, :z] = ints[3:3:end]
    end
    return g
end
