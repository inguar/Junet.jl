const SIDE_COEF_SQUARE = 1 / 2
const SIDE_COEF_CIRCLE = 1 / sqrt(pi)
const SIDE_COEF_DIAMOND = sqrt(2) / 2
const SIDE_COEF_TRIANGLE = sqrt(2 / (3 * sqrt(3/2)))
const SIDE_COEF_PENTAGON = sqrt(2 / (5 * sin(1.2566)))
const SIDE_COEF_HEXAGON = sqrt(2 / (6 * sin(1.0472)))
const SIDE_COEF_OCTAGON = sqrt(2 / (8 * sin(0.7854)))


function _polygon_radius(a::Real, n::Integer, r::Real, start::Real=-pi/2)
    a -= start
    while true
        if a > 2pi / n
            a -= 2pi / n
        elseif a < 0
            a += 2pi / n
        else
            break
        end
    end
    return r * cos(pi / n) / cos(pi / n - a)
end

"""
    node_radius(::Type{Val{:shape}}, s::Real, a::Real)

Get the distance between the center and the edge of a node at angle `a`.
The node is of shape `:shape` and size `s`.
"""
node_radius(_, s::Real, a::Real) = s / 2

node_radius(::Type{Val{:square}}, s::Real, a::Real) = 
    s * SIDE_COEF_SQUARE / max(abs(sin(a)), abs(cos(a)))

node_radius(::Type{Val{:circle}}, s::Real, a::Real) = s * SIDE_COEF_CIRCLE

node_radius(::Type{Val{:diamond}}, s::Real, a::Real) = 
    s * SIDE_COEF_DIAMOND / (1 + abs(sin(a) / cos(a))) / abs(cos(a))

node_radius(::Type{Val{:triangle}}, s::Real, a::Real) = 
    _polygon_radius(a, 3, s * SIDE_COEF_TRIANGLE)

node_radius(::Type{Val{:pentagon}}, s::Real, a::Real) = 
    _polygon_radius(a, 5, s * SIDE_COEF_PENTAGON)

node_radius(::Type{Val{:hexagon}}, s::Real, a::Real) = 
    _polygon_radius(a, 6, s * SIDE_COEF_HEXAGON)

node_radius(::Type{Val{:octagon}}, s::Real, a::Real) = 
    _polygon_radius(a, 8, s * SIDE_COEF_OCTAGON, pi/8)


function _polygon_path(context::CairoContext, x, y, n, r, start=-pi/2)
    a = start
    move_to(context, x + r * cos(a), y + r * sin(a))
    for i = 1:n-1
        a += 2pi / n
        line_to(context, x + r * cos(a), y + r * sin(a))
    end
    close_path(context)
end

"""
    node_path(::Type{Val{:shape}}, context, x, y, s)

Create a path on a Cairo `context` that corresponds to `:shape` of size `s`.
"""
node_path(_, context, x, y, r) = nothing

node_path(::Type{Val{:circle}}, context, x, y, r) = circle(context, x, y, r * SIDE_COEF_CIRCLE)

node_path(::Type{Val{:square}}, context, x, y, r) = rectangle(context,
    x - r * SIDE_COEF_SQUARE, y - r * SIDE_COEF_SQUARE, r, r)

node_path(::Type{Val{:diamond}}, context, x, y, side) = begin
    move_to(context, x - side * SIDE_COEF_DIAMOND, y)
    line_to(context, x, y - side * SIDE_COEF_DIAMOND)
    line_to(context, x + side * SIDE_COEF_DIAMOND, y)
    line_to(context, x, y + side * SIDE_COEF_DIAMOND)
    close_path(context)
end

node_path(::Type{Val{:triangle}}, context, x, y, side) = 
    _polygon_path(context, x, y, 3, side * SIDE_COEF_TRIANGLE)

node_path(::Type{Val{:pentagon}}, context, x, y, side) = 
    _polygon_path(context, x, y, 5, side * SIDE_COEF_PENTAGON)

node_path(::Type{Val{:hexagon}}, context, x, y, side) = 
    _polygon_path(context, x, y, 6, side * SIDE_COEF_HEXAGON)

node_path(::Type{Val{:octagon}}, context, x, y, side) = 
    _polygon_path(context, x, y, 8, side * SIDE_COEF_OCTAGON, pi/8)
