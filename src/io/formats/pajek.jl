#= Read and write Pajek files

Most of things specified in the format (like node and edge attributes) are supported.
See [1](http://www.pfeffer.at/txt2pajek/txt2pajek.pdf), and
[2](http://vlado.fmf.uni-lj.si/pub/networks/pajek/doc/draweps.htm)
for the reference. =#

const PAJEK_ATTRIBUTES = Dict("ic"=>:color, "c"=>:color, "w"=>:width, "l"=>:label,
    "bw"=>:border_width, "fos"=>:font_size, "lr"=>:label_angle, "s"=>:arrow_size)

const PAJEK_ATTR_DEFAULTS = Dict(:label => "", :shape => :circle,
    :color => "Grey", :weight => 1., :width => 1.)

const PAJEK_SHAPES = Dict("box" => :square, "triangle" => :triangle,
    "ellipse" => :circle, "diamond" => :diamond)


function _skip_to_header(io::IO)
    for line in eachline(io)
        line[1] == '*' && return line
    end
end

function _is_directed_lookahead(io::IO)
    pos = position(io)
    for line in eachline(io)
        if line[1] == '*' && contains(line, "Arcs")
            seek(io, pos)
            return true
        end
    end
    seek(io, pos)
    return false
end

function _parse_nodes(io::IO, g::Graph, header::String, parse_attrs::Bool)
    n = parse(Int, split(header)[end])
    addnodes!(g, n)
    if !parse_attrs
        return _skip_to_header(io)
    else
        for line in eachline(io)
            line[1] == '*' && return line

            tokens = split(line)
            ind = parse(Int, shift!(tokens))
            attrs = Dict{Symbol,Any}(:label => String(strip(shift!(tokens), '"')))

            i = 1
            while length(tokens) > 0
                token = shift!(tokens)
                if i < 4 && !isalpha(token[1])  # coordX, coordY, value, and/or shape
                    attrs[(:x, :y, :size)[i]] = float(token)
                elseif token in ("box", "triangle", "ellipse", "diamond")
                    attrs[:shape] = PAJEK_SHAPES[token]
                elseif token == "ic"            # color
                    if length(tokens) > 0
                        attrs[:color] = String(shift!(tokens))
                    end
                elseif length(tokens) > 0
                    attrs[Symbol(token)] = float(shift!(tokens))
                end
                i += 1
            end

            for (k, v) = attrs
                if !hasnodeattr(g, k)
                    default = get(PAJEK_ATTR_DEFAULTS, k, 0.)
                    addnodeattr!(g, k, default)
                end
                g.nodeattrs[k, ind] = v
            end
        end
    end
end

function _parse_edges(io::IO, g::Graph, directed::Bool, parse_attrs::Bool)
    for line in eachline(io)
        line[1] == '*' && return line

        tokens = split(line)
        x, y = parse(Int, shift!(tokens)), parse(Int, shift!(tokens))
        attrs = Dict{Symbol,Any}()

        if parse_attrs
            i = 1
            while length(tokens) > 0
                t = shift!(tokens)
                if i == 1 && isnumber(t[1])
                    attrs[:weight] = float(t)
                elseif length(tokens) > 0
                    if t == "l"
                        attrs[:label] = String(strip(shift!(tokens), '"'))
                    elseif t == "w"
                        attrs[:width] = float(shift!(tokens))
                    elseif t == "c"
                        attrs[:color] = String(shift!(tokens))
                    else
                        t_ = shift!(tokens)
                        attrs[Symbol(t)] = t_[1] == '"' ? String(strip(t_, '"')) : float(t_)
                    end
                end
                i += 1
            end
            for k = keys(attrs)
                if !hasedgeattr(g, k)
                    default = get(PAJEK_ATTR_DEFAULTS, k, 0.)
                    addedgeattr!(g, k, default)
                end
            end
        end

        addedge!(g, x, y; attrs...)
        isdirected(g) && !directed && addedge!(g, y, x; attrs...)
    end
end


"""
    read_pajek(io::IO[; parse_attrs=true])

Read graph from a Pajek-formatted file.

Since Pajek format is not very well documented, there may be errors parsing
some files. Most of the errors will come from parsing the node and edge attributes.
To suppress it, pass `parse_attrs=false` to this function, which also
dramatically speeds up the parsing.
"""
function read_pajek(io::IO; parse_attrs=true)
    g = Graph(directed=_is_directed_lookahead(io))
    header = _skip_to_header(io)
    while !eof(io)
        header = lowercase(header)
        if contains(header, "vertices")
            header = _parse_nodes(io, g, header, parse_attrs)
        elseif contains(header, "arcs")
            header = _parse_edges(io, g, true, parse_attrs)
        else # "edges"
            header = _parse_edges(io, g, false, parse_attrs)
        end
    end
    return g
end


"""
    writepajek(filename, g::Graph)

Serialize the `Graph` instance `g` in Pajek format.
"""
function writepajek(filename, g)
    f = open(filename, "w")
    # Nodes
    println(f, "*Vertices $(nodecount(g))")
    if hasnodeattr(g, :label)
        for (i, l) = enumerate(g[:, :label])
            println(f, i, '"', l, '"')
        end
    end
    # Edges
    println(f, isdirected(g) ? "*Arcs" : "*Edges")
    for e = edges(g)
        println(f, e.source, ' ', e.target)
    end
    close(f)
end
