__precompile__()

module Junet


# Use-only imports
import GZip             # for io/edgelist.jl
using Cairo             # for draw/plot.jl
import Colors: RGB      # for draw/plot.jl

# Imports to extend Base
import Base:
    length, size, getindex, setindex!,  # common
    @_inline_meta, @_propagate_inbounds_meta,
    isless, ==,             # primitives.jl
    reverse, transpose,     # graph.jl
    deleteat!, endof,       # attributes.jl
    ndims, start, next, done, endof, eltype,  # edgeiter.jl
    push!, pop!, rand,      # util/rand_dist.jl
    Matrix,                 # io/matrix.jl
    summary, show           # io/show.jl


include("params.jl")                        # getting to a minimally usable state
include("primitives.jl")
include("graph.jl")
include("attributes.jl")
include("graph_info.jl")
include("graph_iter.jl")
include("graph_operations.jl")

include("util/rand_dist.jl")                # commonly used methods
include("util/relabel.jl")

include("generate/classic.jl")              # graph generators
include("generate/random.jl")
include("generate/small_world.jl")
include("generate/preferential.jl")

include("measure/centrality/degree.jl")     # graph measures
include("measure/centrality/subtree.jl")
include("measure/centrality/power_iter.jl")
include("measure/centrality/closeness.jl")

include("measure/dyadic.jl")

include("measure/triadic/clustering.jl")

include("measure/global/components.jl")
include("measure/global/k-core.jl")

include("community/label_propagation.jl")   # community detection

include("io/show.jl")                       # input/output
include("io/matrix.jl")
include("io/formats/edgelist.jl")
include("io/formats/pajek.jl")
include("io/formats/ngraph.jl")
include("io/formats/ucinet.jl")
include("io/file_io.jl")

include("draw/layout.jl")                   # visualization
include("draw/node_paths.jl")
include("draw/edge_paths.jl")
include("draw/styles.jl")
include("draw/plot.jl")


export
    Graph, DirectedGraph, UndirectedGraph,  # graph.jl
    MultiGraph, SimpleGraph, LightGraph,
    isdirected, ismultigraph, directed, undirected,

    nodes, nodecount,                       # graph_info.jl
    edgecount, maxedgecount,

    neighbors, outneighbors, inneighbors,   # graph_iter.jl
    edges, outedges, inedges,
    getindex, setindex!,

    addnode!, addnodes!,                    # graph_operations.jl
    remnode!, remnodes!,
    addedge!, addedges!, hasedge,
    remedge!, remedges!,
    addnodeattr!, addedgeattr!,
    addnodeattrs!, addedgeattrs!,

    # generate/
    graph_path, graph_cycle, graph_star, graph_wheel, graph_complete,
    graph_grid, graph_web, graph_tree,
    graph_gilbert, graph_erdos_renyi, graph_random, graph_erdosrenyi,
    graph_smallworld, graph_preferential,

    # measure/centrality/
    degree, indegree, outdegree,        # degree.jl
    isolates, isolatecount,
    leaves, leafcount,
    sources, sourcecount,
    sinks, sinkcount,

    subtree_size,                       # subtree.jl

    eigenvector, pagerank,              # power_iter.jl

    closeness, harmonic_centrality,     # closeness.jl

    # measure/dyadic.jl
    density, mutuality, reciprocity, dyadcensus,
    selfloopcount, selfloopnodes,

    # measure/triadic/
    maxtrianglecount, triangles, clustering,

    # measure/global/
    components, kcores,

    # io/
    readgraph,

    # community/
    label_propagation,

    # draw/
    layout_random, layout_circle, layout_line,
    layout_fruchterman_reingold,
    plot

end
