using Junet
using Base.Test


@testset "primitives.jl" begin
    @testset "NodePtr" begin
        @test Junet.NodePtr(1, 2) < Junet.NodePtr(2, 2)
        @test Junet.NodePtr(2, 1) > 1
    end

    @testset "Node" begin
        n = Junet.Node{Int,Int}([], [])
        @test length(n.forward) == length(n.reverse) == 0
        push!(n.forward, Junet.NodePtr(1, 2))
        @test length(n.forward) == 1
    end
end

@testset "graph.jl" begin
    g = Graph()
    ug = Graph(directed=false)

    @testset "directed?" begin
        @test isdirected(g)
        @test !isdirected(ug)

        @test typeof(directed(g)) <: DirectedGraph
        @test typeof(directed(ug)) <: DirectedGraph
        @test typeof(undirected(g)) <: UndirectedGraph
        @test typeof(undirected(ug)) <: UndirectedGraph

        @test typeof(g'') == typeof(g)
        @test typeof(ug') == typeof(ug)
    end
    
    @testset "multigraph?" begin
        @test ismultigraph(g)
        @test ismultigraph(ug)

        lg = Graph(edgeids=Void)
        @test typeof(lg) <: LightGraph
    end

    @testset "node add/remove/count" begin
        for i = 1:10
            addnode!(g)
            @test nodecount(g) == i
        end
        addnode!(g, 10)
        @test nodecount(g) == 20
        for i = 19:-1:0
            remnode!(g, rand(nodes(g)))
            @test nodecount(g) == i
        end
    end
end
