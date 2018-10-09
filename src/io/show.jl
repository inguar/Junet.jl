## Pretty printing of Junet types ##

typestr(g::Graph) = string(
    nodecount(g), "-node ",
    edgecount(g), "-edge ",
    isdirected(g) ? "directed " : "undirected ",
    ismultigraph(g) ? "multigraph" : "graph")

memstr(m::Integer) =
    if m < 1024
        "< 1 KiB"
elseif m < 1024^2
        string(round(m / 1024, digits=1), " KiB")
elseif m < 1024^3
    string(round(m / 1024^2, digits=2), " MiB")
    else
    string(round(m / 1024^3, digits=3), " GiB")
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

# TODO: make this work with EdgeIter and potential other iterators
function show(io::IO, x::PtrView)
    print(io, length(x), "-element Junet.PtrView with ", eltype(x), " values")
    if !get(io, :limit, false)
        screenheight = 20
    else
        sz = displaysize(io)
        screenheight = sz[1] - 4
    end
    screenheight < 5 || length(x) == 0 && return
    println(io)
    if length(x) < screenheight
        for i = 1:length(x)
            if i < length(x)
                println(io, ' ', x[i])
            else
                print(io, ' ', x[i])
            end
        end
    else
        halfheight = div(screenheight, 2) - 1
        for i = 1:halfheight
            println(io, ' ', x[i])
        end
        println(io, " ⋮")
        for i = length(x) - halfheight:length(x)
            if i < length(x)
                println(io, ' ', x[i])
            else
                print(io, ' ', x[i])
            end
        end
    end
end
