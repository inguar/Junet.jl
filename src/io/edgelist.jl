import GZip


const _delims = [Base._default_delims,
        [',', '"', '\n', '\r'], [';', '"', '\n', '\r']]

function readedgelist(io::IO; delim=:auto, directed=:auto, kvargs...)
    # Skip comments, try to extract information about directedness if available
    local line
    dir = isa(directed, Bool) ? Bool(directed) : true
    while (line = readline(io))[1] == '#'
        if directed == :auto
            t = lowercase(get(split(line), 2, ""))
            if t == "undirected"
                dir = false
                directed = :ok
            end
        end
    end
    # Determine the delimiter
    if isa(delim, Vector{Char})
        dlm = delim
    elseif isa(delim, Char)
        dlm = [delim, '\r', '\n']
    elseif delim == :auto
        for dlm = _delims
            if length(split(line, dlm, keep=false)) > 1
                delim = :ok
                break
            end
        end
        delim != :ok && error("Could not pick the delimiter automatically")
    else
        error("Bad delimiter specification")
    end
    # Read the main part of the file, possibly containing header
    push!(kvargs, (:directed, dir))
    g = Graph(;kvargs...)
    while true
        try
            x, y = split(line, dlm, keep=false)[1:2]
            x = parse(Int, x) + 1
            y = parse(Int, y) + 1
            while nodecount(g) < max(x, y)
                addnode!(g)
            end
            addedge!(g, x, y)
        finally
            eof(io) && break
            line = readline(io)
        end
    end
    return g
end


"""

Currently supported formats are:
  - :delim — delimited files, including `*.tsv`, `*.csv`, and SNAP-style `*.txt` files
  - :pajek — Pajek's `*.paj` and `*.net` files
  - :gml   — Graph Modeling Language (GML) file

  - :gdf   — GUESS file (https://gephi.org/users/supported-graph-formats/gdf-format/)

  - :graphml — GraphML files
  - :ucinet  — UCINet's `*.ucn` files

  - :junet     — Junet's own binary format, allows for fast reads and writes
  - :graphtool — graph-tool's binary format
  - :vivagraph — VivaGraph's binary format

See the excellent [Gephi manual](https://gephi.org/users/supported-graph-formats/)
for the overview of different formats.
"""
function readgraph(filename; format=:auto, gzip=:auto, kvargs...)
    extensions = split(lowercase(basename(filename)), '.')[2:end]
    matchext(exts...) = any(i -> i in extensions, exts)
    if format == :auto
        if matchext("tsv", "csv", "txt")
            format = :delim
        elseif matchext("net", "paj")
            format = :pajek
        else
            error("Could not determine file format automatically")
        end
    end
    if gzip == :auto
        gzip = matchext("gz", "gzip")
    end
    f = gzip ? GZip.open(filename) : open(filename)
    if format == :delim
        g = readedgelist(f; kvargs...)
    elseif format == :pajek
        g = readpajek(f)
    end

    close(f)
    return g
end
