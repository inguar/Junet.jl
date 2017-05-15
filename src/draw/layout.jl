# Graph layout procedures.

layout_random(g::Graph) = (rand(nodecount(g)), rand(nodecount(g)))

function layout_fruchterman_reingold(g::Graph, maxiter=30)
    temp = 2.
    n    = nodecount(g)
    x    = 2 * rand(n) .- 1.0
    y    = 2 * rand(n) .- 1.0
    const k = 2. * sqrt(4.0 / n)
    @inbounds for iter = 1:maxiter
        force_x, force_y = zeros(Float64, n), zeros(Float64, n)
        for i = 1:n
            for j = 1:n                 # repulsive forces
                j >= i && break
                d_x, d_y = x[j] - x[i], y[j] - y[i]
                d2 = d_x^2 + d_y^2
                force_x[i] -= d_x * k^2 / d2
                force_y[i] -= d_y * k^2 / d2
                force_x[j] += d_x * k^2 / d2
                force_y[j] += d_y * k^2 / d2
            end
            for j = NodeIDView(g.nodes[i], Forward)  # attractive forces
                d_x, d_y = x[j] - x[i], y[j] - y[i]
                d = sqrt(d_x^2 + d_y^2)
                force_x[i] += d_x * (d/k - k^2/d^2)
                force_y[i] += d_y * (d/k - k^2/d^2)
                force_x[j] -= d_x * (d/k - k^2/d^2)
                force_y[j] -= d_y * (d/k - k^2/d^2)
            end
        end
        t = temp / iter
        for i = 1:n                     # apply forces
            force_mag = sqrt(force_x[i]^2 + force_y[i]^2)
            scale     = min(force_mag, temp)/force_mag
            if !isnan(force_x[i])
                x[i] += force_x[i] * scale
            end
            if !isnan(force_y[i])
                y[i] += force_y[i] * scale
            end
        end
    end
    return x, y
end
