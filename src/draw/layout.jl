## Graph layouts ##

"""
    layout_random(g::Graph)

Place nodes at random positions. They are uniformly distributed along each axis.
"""
layout_random(g::Graph) = (rand(nodecount(g)), rand(nodecount(g)))

"""
    layout_line(g::Graph)

Place nodes on a horisontal line.
Combining this layout with `edge_curve=1` when plotting yields an
[arc diagram](https://en.wikipedia.org/wiki/Arc_diagram).
"""
layout_line(g::Graph) = (
        [Float64(i) for i = nodes(g)], ones(Float64, nodecount(g)))

"""
    layout_circle(g::Graph[, clockwise=true])

Place nodes on a circle, a.k.a. [circular layout](https://en.wikipedia.org/wiki/Circular_layout).
Set `clockwise` to change node ordering.
"""
function layout_circle(g::Graph, clockwise=true)
    Δα = 2 * pi / nodecount(g) * (clockwise ? 1 : -1)
    α0 = -pi / 2 - Δα
    return (
        Float64[cos(α0 + Δα * i) for i = nodes(g)],
        Float64[sin(α0 + Δα * i) for i = nodes(g)])
end

"""
    layout_fruchterman_reingold(g::Graph[; maxiter, scale...)

Layout network with Fruchterman-Reingold force-directed algorithm.

# References

Fruchterman, Thomas MJ, and Edward M Reingold. 1991.
“Graph Drawing by Force-Directed Placement.” Software: Practice and Experience 21 (11):1129–64.
"""
function layout_fruchterman_reingold(g::Graph; maxiter=250, scale=sqrt(nodecount(g)), init_temp=sqrt(nodecount(g)))
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


"""
    rescale(v, newmax, margin)

Rescale elements of `v` to fill range `margin:newmax - margin`.
"""
function rescale(v, newmax::Real, margin::Real) :: Vector{Float64}
    if length(v) == 0
        return Float64[]
    end
    oldmin, oldmax = extrema(v)
    if oldmax > oldmin
        k = (newmax - 2margin) / (oldmax - oldmin)
        return Float64[round(margin + (x - oldmin) * k) for x = v]
    else
        return Float64[newmax / 2 for x = v]
    end
end
