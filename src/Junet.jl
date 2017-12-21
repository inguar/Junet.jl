__precompile__()

module Junet

# Use-only imports
import GZip     # for io/edgelist.jl
using Cairo     # for draw/plot.jl
import Colors: color_names, RGB    # for draw/plot.jl

# Imports to extend Base
import Base:
    length, size, getindex, setindex!,  # common
    @_inline_meta, @_propagate_inbounds_meta,
    isless, ==,             # primitives.jl
    sizehint!, delete!, eachindex, similar,   # attributes.jl
    ndims, start, next, done, endof, eltype,  # edgeiter.jl
    reverse, transpose,     # graph.jl
    push!, pop!, rand,      # util/rand_dist.jl
    Matrix,                 # io/matrix.jl
    summary, show           # io/show.jl

include("params.jl")                        # getting to a minimally usable state
include("primitives.jl")
include("attributes.jl")
include("graph.jl")
include("edgeiter.jl")
include("graph_operations.jl")

include("util/rand_dist.jl")                # commonly used methods
include("util/relabel.jl")

include("generate/erdos_renyi.jl")          # graph generators
include("generate/geometric.jl")
include("generate/small_world.jl")
include("generate/preferential.jl")

include("measure/centrality/degree.jl")     # graph measures
include("measure/centrality/subtree.jl")
include("measure/centrality/power_iter.jl")

include("measure/dyadic.jl")

include("measure/triadic/clustering.jl")

include("measure/global/components.jl")
include("measure/global/k-core.jl")

include("community/label_propagation.jl")   # community detection

include("io/show.jl")                       # input/output
include("io/matrix.jl")
include("io/edgelist.jl")
include("io/pajek.jl")
include("io/ngraph.jl")

include("draw/layout.jl")                   # visualization
include("draw/node_shapes.jl")
include("draw/plot.jl")

export Graph,
    DirectedGraph, UndirectedGraph,
    MultiGraph, SimpleGraph,
    LightGraph,

    # graph.jl
    isdirected, ismultigraph, directed, undirected,
    nodecount, nodes, addnode!, remnode!,
    edgecount, hasedge, addedge!, remedge!, remedges!,

    neighbors, outneighbors, inneighbors,
    edges, outedges, inedges,
    getindex, setindex!,

    # measure/dyad.jl
    maxedgecount, density, reciprocity, dyadcensus,
    selfloopcount, selfloopnodes,

    # measure/degree.jl
    degree, indegree, outdegree,
    isolates, isolatecount,
    leaves, leafcount,
    sources, sourcecount,
    sinks, sinkcount,

    # measures/subtree.jl
    subtree_size,

    # measure/components.jl
    components,

    # measure/clustering.jl
    maxtrianglecount, triangles, clustering,

    # measure/power_iter.jl
    eigenvector, pagerank,

    # measure/k-core.jl
    kcores,

    # io/
    readgraph,

    # generator/
    graph_path, graph_cycle, graph_star, graph_wheel, graph_complete,
    graph_tree, graph_erdosrenyi, graph_smallworld, graph_preferential,

    # community/
    label_propagation,

    # draw/
    layout_random, layout_circle, layout_fruchterman_reingold,
    plot

end
