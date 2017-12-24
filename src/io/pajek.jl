#= Read and write Pajek files

Most of things specified in the format (like node and edge attributes) are supported.
See [1](http://www.pfeffer.at/txt2pajek/txt2pajek.pdf), and
[2](http://vlado.fmf.uni-lj.si/pub/networks/pajek/doc/draweps.htm)
for the reference.
=#

const _defvalues = Dict(
    :label  => "",
    :shape  => :ellipse,
    :color  => "Grey",
    :weight => 1.,
    :width  => 1.
)

const _names = Dict(
    "l"     => :label,
    "ic"    => :color,
    "w"     => :width,
    "c"     => :color
)

function readpajek(io::IO)
    g = Graph()
    # Create `n` nodes and read their attributes
    n = parse(Int, split(readline(io))[end])
    g[:, :label] = string("") #[""]
    for i = 1:n
        tokens = split(readline(io))[2:end]
        attrs = Dict{Symbol,Any}(:label => strip(shift!(tokens), '"'))
        j = 1
        while length(tokens) > 0
            t = shift!(tokens)
            if j < 4 && !isalpha(t)
                attrs[(:x, :y, :z)[j]] = float(t)
            elseif t in ("box", "triangle", "ellipse", "diamond")
                attrs[:shape] = Symbol(t)
            elseif t == "ic"
                try
                    attrs[:color] = shift!(tokens)
                catch
                    nothing
                end
            elseif length(tokens) > 1
                attrs[Symbol(t)] = float(shift!(tokens))
            end
            j += 1
        end
        if j > 1
            for a = keys(attrs)
                if !hasnodeattr(g, a)
                    v = get(_defvalues, a, 0.)
                    g[:, a] = v #i == 1 ? [v] : v  # dense vs sparse attribute
                end
            end
        end
        addnode!(g, attrs)
    end
    # Determine if the whole graph is undirected so we could save space
    pos = position(io)
    dir, arcs = false, true
    while !eof(io)
        line = readline(io)
        dir && strip(line) == "" && continue
        if line[1] == '*'
            arcs = contains(line, "Arcs")
        elseif arcs
            dir = true
            break
        end
    end
    if !dir
        g = undirected(g)
    end
    seek(io, pos)
    # Add the graph's edges and their attributes
    i = 1
    while !eof(io)
        tokens = split(readline(io))
        length(tokens) == 0 && continue
        if tokens[1][1] == '*'   # change the edge adding mode
            arcs = lowercase(tokens[1]) == "*arcs"
            continue
        else
            x, y = parse(Int, shift!(tokens)), parse(Int, shift!(tokens))
            attrs = Dict{Symbol,Any}()
            j = 1
            while length(tokens) > 0
                t = shift!(tokens)
                if j == 1 && !isalpha(t)
                    attrs[:weight] = float(t)
                elseif t == "l"
                    attrs[:label] = strip(shift!(tokens), '"')
                elseif t == "w"
                    attrs[:width] = float(shift!(tokens))
                elseif t == "c"
                    attrs[:color] = shift!(tokens)
                else
                    t_ = shift!(tokens)
                    attrs[Symbol(t)] = t_[1] == '"' ? strip(t_, '"') : float(t_)
                end
                j += 1
            end
            if j > 1
                for a = keys(attrs)
                    if !hasedgeattr(g, a)
                        v = get(_defvalues, a, 0.)
                        g[:, :, a] = v #i == 1 ? [v] : v  # dense vs sparse attribute
                    end
                end
            end
            addedge!(g, x, y, attrs)
            dir && !arcs && addedge!(g, y, x, attrs...)
        end
        i += 1
    end
    g
end

"""
    writepajek(filename, g::Graph)

Serialize the `Graph` instance `g` in Pajek format.
"""
function writepajek(filename, g)
    f = open(filename, "w")
    # Nodes
    n = nodecount(g)
    println(f, "*Vetrices $n")
    for i = 1:n
        println(f, "$i \"$i\"")
    end
    # Edges
    println(f, isdirected(g) ? "*Arcs" : "*Edges")
    for e = edges(g)
        println(f, "$(e.source) $(e.target)")
    end
    close(f)
end
