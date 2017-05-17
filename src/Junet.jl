module Junet

include("params.jl")                # getting to a minimally usable state
include("primitives.jl")
include("views.jl")
include("attributes.jl")
include("sorted.jl")
include("graph.jl")
include("measure/dyad.jl")          # graph measures
include("measure/degree.jl")
include("measure/power_iter.jl")
include("measure/components.jl")
include("measure/k-core.jl")
include("measure/clustering.jl")
include("generator/erdos_renyi.jl")
include("generator/geometric.jl")
include("generator/small_world.jl")
include("generator/rand_dist.jl")
include("generator/preferential.jl")
include("io/show.jl")               # input/output
include("io/pajek.jl")
include("io/edgelist.jl")
include("draw/layout.jl")           # visualization
include("draw/plot.jl")

export Graph, DirectedGraph, UndirectedGraph, MultiGraph, SimpleGraph,
        LightGraph,

        # graph.jl
        isdirected, ismultigraph, directed, undirected, reverse,
        nodecount, nodes, hasnode, addnode!, remnode!,
        edgecount, edges, hasedge, addedge!, remedge!,

        neighbors, outneighbors, inneighbors,
        edges, outedges, inedges,
        getindex, setindex!,

        # measure/dyad,jl
        maxedgecount, density, reciprocity, dyadcensus,
        selfloopcount, selfloopnodes,

        # measure/degree.jl
        degree, indegree, outdegree,
        isolates, isolatecount,
        leaves, leafcount,
        sources, sourcecount,
        sinks, sinkcount,

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
        path, cycle, star, wheel, complete, tree,
        erdosrenyi, smallworld, preferential,

        # draw/
        plot,
        layout_random, layout_circle, layout_fruchterman_reingold




end
