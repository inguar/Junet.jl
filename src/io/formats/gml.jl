## A simple self-contained GML parser ##

const GML_REGEX_TOKEN = r"[a-zA-Z0-9\+\-\.]+"
const GML_REGEX_STRING = r"\"[^\"]*\""

mutable struct ReaderState{I<:IO}
    io::I
    cur_line::String
    cur_char::Int
end

match_length(r::Regex, s::ReaderState) = length(match(r, s.cur_line, s.cur_char).match)

function next_token(s::ReaderState)::String
    while s.cur_char > length(s.cur_line)   # get new line if finished
        eof(s.io) && return ""
        line = strip(chomp(readline(s.io)))
        if length(line) == 0 || line[1] == '#'
            continue
        end
        s.cur_line = line
        s.cur_char = 1
    end
    c = s.cur_line[s.cur_char]
    while c == ' ' || c == '\t'             # skip whitespace
        s.cur_char += 1
        c = s.cur_line[s.cur_char]
    end
    if c == '[' || c == ']'                 # different kinds of tokens
        r = s.cur_char:s.cur_char
    elseif c == '"'
        r = s.cur_char:s.cur_char + match_length(GML_REGEX_STRING, s) - 1
    else
        r = s.cur_char:s.cur_char + match_length(GML_REGEX_TOKEN, s) - 1
    end
    s.cur_char = r.stop + 1
    return s.cur_line[r]
end

function read_list(s::ReaderState)
    list = Vector{Tuple{Symbol,Any}}()
    while true
        t1 = next_token(s)
        (t1 == "]" || t1 == "") && break
        t2 = next_token(s)
        (t2 == "]") && error("unpaired key")
        if t2 == "["
            push!(list, (Symbol(t1), read_list(s)))
        else
            push!(list, (Symbol(t1), parse(t2)))
        end
    end
    return list
end

function get_key(list, key, default)
    for (k, v) = list
        k == key && return v
    end
    return default
end

iter_key(list, key) = (v for (k, v) = list if k == key)

# TODO: auto-detect start_id as min(graph.node.id)
# TODO: reorganize this for fewer memory allocations (igraph is noticeably faster)

function make_graph(list::Vector{Tuple{Symbol,Any}}, start_id)
    dir = Bool(get_key(list, :directed, 0))
    g = Graph(directed=dir)
    for node = iter_key(list, :node)
        attrs = Dict{Symbol,Any}()
        id = -1
        prune = Int[]
        for (i, (k, v)) = enumerate(node)
            if k == :id
                id = v
                push!(prune, i)
            elseif !isleaftype(typeof(v))
                push!(prune, i)
            end
        end
        id == -1 && continue
        deleteat!(node, prune)
        for (k, v) = node
            if !hasnodeattr(g, k)
                addnodeattr!(g, k, defval(typeof(v)))
            end
        end
        if id > nodecount(g) - start_id
            addnodes!(g, id - nodecount(g) - start_id)
        end
        addnode!(g; node...)
    end
    for edge = iter_key(list, :edge)
        attrs = Dict{Symbol,Any}()
        src, tgt = -1, -1
        prune = Int[]
        for (i, (k, v)) = enumerate(edge)
            if k == :source
                src = v + 1 - start_id
                push!(prune, i)
            elseif k == :target
                tgt = v + 1 - start_id
                push!(prune, i)
            elseif !isleaftype(typeof(v))
                push!(prune, i)
            end
        end
        deleteat!(edge, prune)
        for (k, v) = edge
            if !hasedgeattr(g, k)
                addedgeattr!(g, k, defval(typeof(v)))
            end
        end
        addedge!(g, src, tgt; edge...)
    end
    return g
end

function read_gml(io::IO; start_id=0, kvargs...)
    r = ReaderState(io, "", 1)
    res = read_list(r)
    graph = get_key(res, :graph, Tuple{Symbol,Any}[])
    return make_graph(graph, start_id)
end

function write_gml(io::IO, g::Graph)
    println(io, "graph [")
    println(io, "\tdirected ", Int(isdirected(g)))
    for n = nodes(g)
        println(io, "\tnode [")
        println(io, "\t\tid ", n)
        println(io, "\t]")
    end
    for e = edges(g)
        println(io, "\tedge [")
        println(io, "\t\tsource ", e.source)
        println(io, "\t\ttarget ", e.target)
        println(io, "\t]")
    end
    println(io, "]")
end
