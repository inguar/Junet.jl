using Junet
using Base.Test

@testset "All tests" begin
    # Tests for "params.jl"
    @testset "Parameter types" begin
        @test Junet.rev(Junet.Forward) == Junet.Reverse
        @test Junet.rev(Junet.Reverse) == Junet.Forward
        @test Junet.rev(Junet.Both) == Junet.Both
    end

    # Tests for "primitives.jl"
    @testset "Primitives (Nodes/Edges)" begin
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

        @testset "Edge" begin
            e = Junet.Edge(1, Junet.NodePtr(2, 3), Junet.Forward, Junet.Forward)
            @test e.source == 1 && e.target == 2 && e.id == 3
            e = Junet.Edge(1, Junet.NodePtr(2, 3), Junet.Reverse, Junet.Forward)
            @test e.source == 1 && e.target == 2 && e.id == 3
            e = Junet.Edge(1, Junet.NodePtr(2, 3), Junet.Both, Junet.Forward)
            @test e.source == 1 && e.target == 2 && e.id == 3

            e = Junet.Edge(1, Junet.NodePtr(2, 3), Junet.Forward, Junet.Reverse)
            @test e.source == 2 && e.target == 1 && e.id == 3
            e = Junet.Edge(1, Junet.NodePtr(2, 3), Junet.Reverse, Junet.Reverse)
            @test e.source == 2 && e.target == 1 && e.id == 3
            e = Junet.Edge(1, Junet.NodePtr(2, 3), Junet.Both, Junet.Reverse)
            @test e.source == 2 && e.target == 1 && e.id == 3

            e = Junet.Edge(1, Junet.NodePtr(2, 3), Junet.Both, Junet.Forward)
            @test e.source == 1 && e.target == 2 && e.id == 3
            e = Junet.Edge(1, Junet.NodePtr(2, 3), Junet.Both, Junet.Forward)
            @test e.source == 1 && e.target == 2 && e.id == 3
            e = Junet.Edge(1, Junet.NodePtr(2, 3), Junet.Both, Junet.Forward)
            @test e.source == 1 && e.target == 2 && e.id == 3
        end
    end

    # Tests for "graph.jl"
    @testset "Graphs" begin
        g = Graph()

        @testset "Type system" begin
            @test Junet.DirectedFwGraph <: DirectedGraph
            @test Junet.DirectedRvGraph <: DirectedGraph
        end

        @testset "Type manipulations" begin
            ug = undirected(g)

            @test isdirected(g)
            @test !isdirected(ug)
            @test typeof(directed(g)) <: DirectedGraph &&
                  typeof(directed(ug)) <: DirectedGraph
            @test typeof(undirected(g)) <: UndirectedGraph &&
                  typeof(undirected(ug)) <: UndirectedGraph

            @test typeof(g) <: Junet.DirectedFwGraph
            @test typeof(reverse(g)) <: Junet.DirectedRvGraph
            @test typeof(reverse(reverse(g))) <: Junet.DirectedFwGraph
            @test typeof(reverse(ug)) == typeof(ug)

            @test ismultigraph(g) && ismultigraph(ug)

            lg = Graph(edgeids=Void)
            @test typeof(lg) <: LightGraph
        end

        @testset "Node add/remove/count" begin
            for i = 1:10
                addnode!(g)
                @test nodecount(g) == i
            end
            addnode!(g, 10)
            @test nodecount(g) == 20
            for i = 1:20
                remnode!(g, rand(1:1))
                @test nodecount(g) == 10 - i
            end

        end

        @testset "Edge add/remove/count" begin
            for i = 1:100
                addnode!(g)
            end
            for i = 1:100

            end
        end

    end

end

# New corner cases:

# memsize(Graph())
