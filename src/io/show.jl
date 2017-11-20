## Pretty printing of Junet types ##

size(g::Graph) = (nodecount(g), edgecount(g))  # FIXME does this belong here?

typestr(g::Graph) = string(
    nodecount(g), "-node ",
    edgecount(g), "-edge ",
    isdirected(g) ? "directed " : "undirected ",
    ismultigraph(g) ? "multigraph" : "graph")

memsize(g::Graph) =
    sizeof(g) + sizeof(g.nodes) +
    sum(Int[sizeof(n.forward) + sizeof(n.reverse) for n = g.nodes]) +
    sizeof(g.nodeattrs) + sizeof(g.edgeattrs)

memstr(m::Integer) =
    if m < 1024
        "< 1 KiB"
    elseif m < 1024 ^ 2
        string(round(m / 1024, 1), " KiB")
    elseif m < 1024 ^ 3
        string(round(m / 1024 ^ 2, 2), " MiB")
    else
        string(round(m / 1024 ^ 3, 3), " GiB")
    end

summary(d::AttributeDict) = join(
    (string(k, " (", eltype(d[k]), ")") for k = keys(d)), ", ")

function edgestr(g::Graph, count=20)
    es = edges(g)
    e = map(string, Base.Iterators.take(es, count))
    res = join(e, ", ")
    if length(es) > count
        res *= "…"
    end
    return res
end

function summary(g::Graph, long=true)
    typ = typestr(g) * " occupying " * memstr(memsize(g))
    nc = length(g.nodeattrs)
    natt = string(nc, " node attributes", nc > 0 ? (": " * summary(g.nodeattrs)) : "")
    ec = length(g.edgeattrs)
    eatt = string(ec, " edge attributes", ec > 0 ? (": " * summary(g.edgeattrs)) : "")
    println(join([typ, natt, eatt], "\n"))
    es = edgecount(g)
    if es > 0
        println("Sample edges: ", edgestr(g))
    end
end

show(io::IO, g::Graph) = print(io, typestr(g))

show(io::IO, n::Node) = print(io,
    "Node with ", ptr_length(n, Both), " adjacent edges")

function show(io::IO, e::NodePtr)
    print(io, "→ ", e.node)
    if e.id != nothing
        print(io, " (id ", e.id, ")")
    else
        print(io, " (no id)")
    end
end

show(io::IO, e::Edge) = print(io,
    e.source, e.isdir ? " → " : " ←→ ", e.target)

# FIXME: there is one redundant newline at the end
# TODO: add the type declaration of the thing that it returns
# TODO: make type declarations consistent ("Junet.X{...}")
# TODO: make something similar for EdgeIter

function show(io::IO, x::PtrView)
    if !get(io, :limit, false)
        screenheight = 20
    else
        sz = displaysize(io)
        screenheight = sz[1] - 4
    end
    halfheight = div(screenheight, 2)
    println(io, length(x), "-element PtrView")
    if length(x) < screenheight
        for i = x
            println(io, ' ', i)
        end
    else
        for i = 1:halfheight
            println(io, ' ', x[i])
        end
        println(io, "⋮")
        for i = length(x) - halfheight:length(x)
            println(io, ' ', x[i])
        end
    end
end


# FIXME: check if the following is not just rubbish at this point

show(io::IO, g::Base.Generator{Vector{NodePtr{N,E}}}) where {N,E} =
    print(io, length(g), "-element edge iterator")

# function show(io::IO, x::NewIter)
#     println(io, length(x), "-element NewIter{...}:")
#     s = start(x)
#     cnt = 0
#     while !done(x, s) && cnt < 10
#         val, s = next(x, s)
#         println(io, " ", val)
#         cnt += 1
#     end
#     done(x, s) || print(io, " ⋮")
# end
