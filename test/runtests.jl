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

        @test_nowarn addnode!(g, 10)
        @test_nowarn addnode!(g, 0)
        @test_throws AssertionError addnode!(g, -1)
        @test nodecount(g) == 20
        
        for i = 19:-1:0
            remnode!(g, rand(nodes(g)))
            @test nodecount(g) == i
        end
    end
end


@testset "generate/" begin
    @testset "classic.jl" begin
        @testset "graph_complete" begin
            for i = 2:10
                @test density(graph_complete(i)) == 1
                @test density(graph_complete(i, directed=false)) == 1
            end
        end

        @testset "graph_tree" begin
            @test_nowarn graph_tree(0, 0)
            @test size(graph_tree(1, 2)) == (3, 2)
            @test size(graph_tree(5, 2)) == (63, 62)
            @test size(graph_tree(4, 4)) == (341, 340)
        end
    end

    @testset "random.jl" begin
        @testset "gilbert_fill!" begin
            g = Graph(directed=true)
            @test_nowarn Junet.gilbert_fill!(g, 1.)
            @test edgecount(g) == 0
            addnode!(g)         # nodecount(g) == 1
            @test_nowarn Junet.gilbert_fill!(g, 1.)
            @test edgecount(g) == 0
            addnode!(g)         # nodecount(g) == 2
            @test_nowarn Junet.gilbert_fill!(g, 1.)
            @test edgecount(g) == 2

            g = Graph(directed=false)
            @test_nowarn Junet.gilbert_fill!(g, 1.)
            @test edgecount(g) == 0
            addnode!(g)         # nodecount(g) == 1
            @test_nowarn Junet.gilbert_fill!(g, 1.)
            @test edgecount(g) == 0
            addnode!(g)         # nodecount(g) == 2
            @test_nowarn Junet.gilbert_fill!(g, 1.)
            @test edgecount(g) == 1
        end

        @testset "graph_gilbert" begin
            @test_nowarn graph_gilbert(0, 0)
            @test_nowarn graph_gilbert(1, 0)
            @test_nowarn graph_gilbert(1, 1)
            @test_throws AssertionError graph_gilbert(10, 2)

            @test density(graph_gilbert(100, 0)) == 0
            @test density(graph_gilbert(100, 0, directed=false)) == 0
            @test density(graph_gilbert(100, 1)) == 1
            @test density(graph_gilbert(100, 1, directed=false)) == 1

            for i = 0:0.1:1.0
                g1 = graph_gilbert(1000, i)
                @test density(g1) ≈ i  atol = .002
                @test selfloopcount(g1) == 0

                g2 = graph_gilbert(1000, i, directed=false)
                @test density(g2) ≈ i  atol = .002
                @test selfloopcount(g2) == 0
            end
        end

        @testset "graph_erdos_renyi" begin
            @test_nowarn graph_erdos_renyi(0, 0)
            @test_nowarn graph_erdos_renyi(1, 0)
            @test_throws ErrorException graph_erdos_renyi(1, 1)
            @test_throws ErrorException graph_erdos_renyi(10, 91)
            @test_throws ErrorException graph_erdos_renyi(10, 46, directed=false)

            for i = 100:100:1000
                j = rand(1:i * (i - 1))
                g1 = graph_erdos_renyi(i, j)
                @test edgecount(g1) == j
                @test selfloopcount(g1) == 0

                j = rand(1:i * (i - 1) >>> 1)
                g2 = graph_erdos_renyi(i, j, directed=false)
                @test edgecount(g2) == j
                @test selfloopcount(g2) == 0
            end
        end

    end

end

