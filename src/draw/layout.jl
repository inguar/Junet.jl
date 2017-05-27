# Graph layout procedures.

layout_random(g::Graph) = (rand(nodecount(g)), rand(nodecount(g)))

layout_circle(g::Graph) =
    ([cos(2*pi*i/nodecount(g)) for i=nodes(g)],
     [sin(2*pi*i/nodecount(g)) for i=nodes(g)])

function Junet.layout_fruchterman_reingold(g::Graph; maxiter=100, c=2.0, init_temp=2.0)
    const n = nodecount(g)
    const k = c * sqrt(π / n)
    x = c .* (rand(n) .- 0.5)
    y = c .* (rand(n) .- 0.5)
    @inbounds for iter = 1:maxiter
        force_x, force_y = zeros(n), zeros(n)
        for i = 1:n
            @inbounds for j = 1:i-1
                d_x, d_y = x[j]-x[i], y[j]-y[i]
                f = - k^2 / (d_x^2 + d_y^2)     # repulsive force
                force_x[i] += d_x * f
                force_y[i] += d_y * f
                force_x[j] -= d_x * f
                force_y[j] -= d_y * f
            end
            @inbounds for j = Junet.NodeIDView(g.nodes[i], Junet.Forward)
                d_x, d_y = x[j]-x[i], y[j]-y[i]
                f = sqrt(d_x^2 + d_y^2) / k     # attractive force
                force_x[i] += d_x * f
                force_y[i] += d_y * f
                force_x[j] -= d_x * f
                force_y[j] -= d_y * f
            end
        end
        t = init_temp / iter
        @inbounds for i = 1:n
            force_mag = sqrt(force_x[i]^2 + force_y[i]^2)  # apply forces
            scale = min(force_mag, t)
            x[i] += force_x[i] * scale
            y[i] += force_y[i] * scale
            d = sqrt(x[i]^2 + y[i]^2)           # don't let points run away
            if d > 1
                x[i] /= d
                y[i] /= d
            end
        end
    end
    return x, y
end
