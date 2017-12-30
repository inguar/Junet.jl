#= Read and write plain-text edgelists

This source code borrows the general parsing scheme from `GraphIO.jl`. =#

const DELIM_REGEX = raw"\s,;|"

function read_edgelist_ids!(io::IO, g::Graph, delim::String, start_id::Integer)
    re = Regex(raw"(\d+)[" * delim * raw"]+(\d+)")
    Δid = 1 - start_id
    for line in eachline(io)
        line = strip(line)
        if length(line) > 0 && line[1] != '#'
            m = match(re, line).captures
            m == nothing && return line
            src = parse(Int, m[1]) + Δid
            tgt = parse(Int, m[2]) + Δid
            while nodecount(g) < max(src, tgt)
                addnode!(g)
            end
            addedge!(g, src, tgt)
        end
    end
end

function read_edgelist_strings!(io::IO, g::Graph, delim::String)
    re = Regex(raw"(\w+)[" * delim * raw"]+(\w+)")
    addnodeattr!(g, :id, String[])
    id_map = Dict{String,Int}()
    create = (x) -> id_map[x] = addnode!(g, id=String(x))
    for line in eachline(io)
        line = strip(line)
        if length(line) > 0 && line[1] != '#'
            m = match(re, line).captures
            m == nothing && return line
            src, tgt = m
            haskey(id_map, src) || create(src)
            haskey(id_map, tgt) || create(tgt)
            addedge!(g, id_map[src], id_map[tgt])
        end
    end
end

"""
    read_edgelist(io::IO[; delim, kvargs...])

Read graph from a plain text file where each line specifies a single edge.
Lines should have the format `source<delims...>target`.
Set the possible delimiters as a string `delim`.

Keyword argument `mode` specifies how to treat the parsed node names:
* `:auto` — try both of the following two options (default),
* `:int` — try to parse numerical ids with the offset `start_id`,
* `:str` — treat node ids as strings (slower and the ordering of resulting 
  node ids can be arbitrary).

If `:int` mode is chosen, it is assumed that node ids in the file start 
with `start_id`, which is zero by default.
If `:str` mode is chosen, the resulting graph has a `String` attribute `:id`
associated with its nodes.
"""
function read_edgelist(io::IO; delim=DELIM_REGEX, mode=:auto, start_id=0, kvargs...)
    if mode == :int || mode == :auto
        pos = position(io)
        g = Graph(; kvargs...)
        res = read_edgelist_ids!(io, g, delim, start_id)
        if res == nothing
            return g
        elseif mode == :int
            error("can't parse line\"$res\"")
        end
        seek(io, pos)
    end
    if mode == :str || mode == :auto
        g = Graph(; kvargs...)
        res = read_edgelist_strings!(io, g, delim)
        if res == nothing
            return g
        else
            error("can't parse line\"$res\"")
        end
    end
end


"""
    write_edgelist(io::IO, g::Graph[; delim, ids])

Write the list of graph's edges, one per line.
If `ids` is not customized, default node ids are used.
"""
function write_edgelist(io::IO, g::Graph; delim='\t', ids=nodes(g) - 1)
    for e = edges(g)
        println(io, repr(ids[e.source]), delim, repr(ids[e.target]))
    end
end
