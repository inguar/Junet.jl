## Graph layouts ##

layout_random(g::Graph) = (rand(nodecount(g)), rand(nodecount(g)))

layout_circle(g::Graph) = ([cos(2*pi*i/nodecount(g)) for i=nodes(g)],
    [sin(2*pi*i/nodecount(g)) for i=nodes(g)])

"""
    layout_fruchterman_reingold(g::Graph, ...)

Layout network with Fruchterman-Reingold force-directed algorithm.

# References

Fruchterman, Thomas MJ, and Edward M Reingold. 1991.
“Graph Drawing by Force-Directed Placement.” Software: Practice and Experience 21 (11):1129–64.
"""
function layout_fruchterman_reingold(g::Graph, maxiter=250, scale=sqrt(nodecount(g)), init_temp=sqrt(nodecount(g)))
    const n = nodecount(g)
    x = scale / 2 .* (rand(n) .- 0.5)
    y = scale / 2 .* (rand(n) .- 0.5)
    @inbounds for iter = 1:maxiter
        force_x, force_y = zeros(n), zeros(n)
        for i = 1:n
            @inbounds for j = 1:i-1
                d_x, d_y = x[j] - x[i], y[j] - y[i]
                f = - 1 / (d_x^2 + d_y^2)           # repulsive force
                force_x[i] += d_x * f
                force_y[i] += d_y * f
                force_x[j] -= d_x * f
                force_y[j] -= d_y * f
            end
            @inbounds for j = map(x->x.node, g.nodes[i].forward)  # TODO: create generic way to handle this 
                d_x, d_y = x[j] - x[i], y[j] - y[i]
                f = n * sqrt(d_x ^ 2 + d_y ^ 2)     # attractive force
                force_x[i] += d_x * f
                force_y[i] += d_y * f
                force_x[j] -= d_x * f
                force_y[j] -= d_y * f
            end
        end
        t = init_temp / iter
        @inbounds for i = 1:n
            force_mag = sqrt(force_x[i] ^ 2 + force_y[i] ^ 2)  # apply forces
            if force_mag > t
                coef = t / force_mag
                x[i] += force_x[i] * coef
                y[i] += force_y[i] * coef
            end
            mag = sqrt(x[i] ^ 2 + y[i] ^ 2)         # don't let points run away
            if mag > scale
                x[i] *= scale / mag
                y[i] *= scale / mag
            end
        end
    end
    return x, y
end
