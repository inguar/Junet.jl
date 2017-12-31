## Umbrella functions to read and write graph file formats ##

"""
    readgraph(filename[; format, gzip, ...])

Load a network from file.

Currently supported formats are:

* `:auto` — try to gess the format from the file's extenstion,
* `:delim` — delimited plain-text file containing one edge per line
  (typically, `*.csv`, `*.tsv`, and `*.txt` extension),
* `:gml` — Graph Modeling Language file (`*.gml`),
* `:pajek` — Pajek file (`*.paj`, `*.net`),
* `:ngraph` — ngraph binary format (`*.bin` + `*.json`).

In the works:

* `:ucinet`  — UCINet files (`*.ucn`),
* `:graphml` — GraphML files (`*.graphml`),
* `:gdf` — GUESS file (https://gephi.org/users/supported-graph-formats/gdf-format/)

See the excellent [Gephi manual](https://gephi.org/users/supported-graph-formats/)
for the overview of different formats.
"""
function readgraph(filename; format=:auto, gzip=:auto, kvargs...)
    extensions = split(lowercase(basename(filename)), '.')[2:end]
    matchext(exts...) = any(i -> i in extensions, exts)
    if format == :auto
        if matchext("txt", "tsv", "csv", "edgelist")
            format = :delim
        elseif matchext("net", "paj")
            format = :pajek
        elseif matchext("gml")
            format = :gml
        elseif matchext("dl")
            format = :ucinet
        else
            error("could not determine file format automatically")
        end
    end
    if gzip == :auto
        gzip = matchext("gz")
    end
    f = gzip ? GZip.open(filename) : open(filename)
    if format == :delim
        g = read_edgelist(f; kvargs...)
    elseif format == :pajek
        g = read_pajek(f; kvargs...)
    elseif format == :gml
        g = read_gml(f; kvargs...)
    elseif format == :ucinet
        g = read_dl(f)
    end
    close(f)
    return g
end
