const PI_2 = pi / 2

_dist(x1, y1, x2, y2) = sqrt(float(x2 - x1)^2 + float(y2 - y1)^2)

_arc_angle(r, d) = 2 * asin(d / 2 / r)


"""
    Line{T}

A type that defines the geometry of a line segment.
"""
mutable struct Line{T<:Real}
    x0 :: T
    y0 :: T
    α  :: T
    Δ1 :: T
    Δ2 :: T
end

Line(x1, y1, x2, y2) = Line(
        float(x1), float(y1), atan(y2 - y1, x2 - x1), 0., _dist(x1, y1, x2, y2))

indent_start!(l::Line, d) = l.Δ1 += d

outdent_end!(l::Line, d) = l.Δ2 -= d

start_point(l::Line) =
    (l.x0 + l.Δ1 * cos(l.α), l.y0 + l.Δ1 * sin(l.α))

function start_offset_points(l::Line, w)
    x1, y1 = start_point(l)
    Δx, Δy = w * cos(l.α + PI_2), w * sin(l.α + PI_2)
    return (x1 - Δx, y1 - Δy, x1, y1, x1 + Δx, y1 + Δy)
end

end_point(l::Line) =
    (l.x0 + l.Δ2 * cos(l.α), l.y0 + l.Δ2 * sin(l.α))

geom_length(l::Line) = l.Δ2 - l.Δ1

is_valid(l::Line) = l.Δ2 > l.Δ1

function outline!(context::CairoContext, l::Line)
    move_to(context, start_point(l)...)
    line_to(context, end_point(l)...)
end


"""
    Arc{T}

A type that defines the geometry of an arc (circle segment).
"""
mutable struct Arc{T<:Real}
    xc :: T
    yc :: T
    r  :: T
    α1 :: T
    α2 :: T
    inv :: Bool
end

# TODO: see if it is possible to eliminate most `inv` checks by reversing α1 and α2

function Arc(x1, y1, x2, y2, curve)
    dist = _dist(x1, y1, x2, y2)
    α⊥ = atan(y2 - y1, x2 - x1) - PI_2 * sign(curve)
    α∠ = curve * PI_2
    α1, α2 = α⊥ - α∠, α⊥ + α∠
    r = dist / 2 / sin(abs(α∠))
    xc, yc = x1 - r * cos(α1), y1 - r * sin(α1)
    return Arc(xc, yc, r, α1, α2, curve < 0)
end

function indent_start!(a::Arc, d)
    Δα = _arc_angle(a.r, d)
    a.α1 += a.inv ? -Δα : Δα
end

function outdent_end!(a::Arc, d)
    Δα = _arc_angle(a.r, d)
    a.α2 += a.inv ? Δα : -Δα
end

start_angle(a::Arc) = a.inv ? a.α1 - PI_2 : a.α1 + PI_2

end_angle(a::Arc) = a.inv ? a.α2 + PI_2 : a.α2 - PI_2

start_point(a::Arc) = (a.xc + a.r * cos(a.α1), a.yc + a.r * sin(a.α1))

function start_offset_points(a::Arc, w)
    x1, y1 = start_point(a)
    α = start_angle(a)
    Δx, Δy = w * cos(α + PI_2), w * sin(α + PI_2)
    return (x1 - Δx, y1 - Δy, x1, y1, x1 + Δx, y1 + Δy)
end

end_point(a::Arc) = (a.xc + a.r * cos(a.α2), a.yc + a.r * sin(a.α2))

function end_tangent(a::Arc, d)
    Δα = _arc_angle(a.r, d) / 2
    return a.inv ? a.α2 - PI_2 - Δα : a.α2 + PI_2 + Δα
end

geom_length(a::Arc) = a.inv ? (a.α1 - a.α2) * a.r : (a.α2 - a.α1) * a.r

is_valid(a::Arc) = xor(a.inv, a.α1 < a.α2)

function outline!(context::CairoContext, a::Arc)
    if !a.inv
        arc(context, round(a.xc, digits=1), round(a.yc, digits=1), round(a.r, digits=1),
            round(a.α1, digits=3), round(a.α2, digits=3))
    else
        arc_negative(context, round(a.xc, digits=1), round(a.yc, digits=1), round(a.r, digits=1),
            round(a.α1, digits=3), round(a.α2, digits=3))
    end
end


"""
    outline_arrow!(context::CairoContext, x, y, α, len, width)

Add a path to Cairo context that outlines an arrow starting
at (x, y) and having certain length and line width.
"""
function outline_arrow!(context::CairoContext, x, y, α, len, width) 
    if width > 3
        arc(context, x, y, width / 2, α - 2.0, α + 2.0)
    else
        move_to(context, x, y)
    end
    l = len * 0.6
    line_to(context, x + l * cos(α + 2.0), y + l * sin(α + 2.0))
    line_to(context, x + len * cos(α), y + len * sin(α))
    line_to(context, x + l * cos(α - 2.0), y + l * sin(α - 2.0))
    close_path(context)
end


###
###     Functions for drawing edges of different shape (line / arrow / tapered)
###

_node_radius(shape, size, a) = node_radius(Val{shape}, sqrt(size), a)

function draw_edge_line!(context::CairoContext, directed,
                    x1, y1, shape1, size1,
                    x2, y2, shape2, size2,
                    width, color, opacity, curve)
    move_to(context, x1, y1)
    line_to(context, x2, y2)
    set_line_width(context, width)
    set_source_rgba(context, color..., opacity)
    stroke(context)
end


function draw_edge_arrow_straight!(context::CairoContext, directed,
                    x1, y1, shape1, size1,
                    x2, y2, shape2, size2,
                    width, color, opacity, curve)
    arrow_size = max(5., width * 1.5)
    l = Line(x1, y1, x2, y2)
    indent_start!(l, _node_radius(shape1, size1, l.α))
    outdent_end!(l, _node_radius(shape2, size2, l.α + pi))
    is_valid(l) || return
    if directed && geom_length(l) > 2arrow_size
        outdent_end!(l, arrow_size)
    else
        directed = false
    end
    outline!(context, l)
    set_line_width(context, width)
    if width > 3
        set_line_cap(context, 1)
    end
    set_source_rgba(context, color..., opacity)
    stroke(context)
    if directed
        outline_arrow!(context, end_point(l)..., l.α, arrow_size, width)
        set_source_rgba(context, color..., opacity)
        fill(context)
    end
end

function draw_edge_arrow_curved!(context::CairoContext, directed,
                    x1, y1, shape1, size1,
                    x2, y2, shape2, size2,
                    width, color, opacity, curve)
    arrow_size = max(5., width * 1.5)
    a = Arc(x1, y1, x2, y2, curve)
    geom_length(a) > sqrt(size1) + sqrt(size2) || return
    indent_start!(a, _node_radius(shape1, size1, start_angle(a)))
    outdent_end!(a, _node_radius(shape2, size2, end_angle(a)))
    is_valid(a) || return
    if directed && geom_length(a) > 2arrow_size
        outdent_end!(a, arrow_size)
    else
        directed = false
    end
    outline!(context, a)
    set_line_width(context, width)
    if width > 3
        set_line_cap(context, 1)
    end
    set_source_rgba(context, color..., opacity)
    stroke(context)
    if directed
        outline_arrow!(context, end_point(a)..., end_tangent(a, arrow_size), arrow_size, width)
        set_source_rgba(context, color..., opacity)
        fill(context)
    end
end

function draw_edge_arrow_selfloop!(context::CairoContext, directed,
                    x1, y1, shape1, size1,
                    x2, y2, shape2, size2,
                    width, color, opacity, curve)
    arrow_size = max(5., width * 1.5)
    r1 = _node_radius(shape1, size1, -pi)
    r2 = _node_radius(shape1, size1, 0)
    a = Arc(x1 - r1, y1, x1 + r2, y1, 1.5 * sign(curve))
    if directed && geom_length(a) > arrow_size
        outdent_end!(a, arrow_size)
    else
        directed = false
    end
    outline!(context, a)
    set_line_width(context, width)
    if width > 3
        set_line_cap(context, 1)
    end
    set_source_rgba(context, color..., opacity)
    stroke(context)
    if directed
        outline_arrow!(context, end_point(a)..., end_tangent(a, arrow_size), arrow_size, width)
        set_source_rgba(context, color..., opacity)
        fill(context)
    end
end


function draw_edge_tapered_straight!(context::CairoContext, directed,
                    x1, y1, shape1, size1,
                    x2, y2, shape2, size2,
                    width, color, opacity, curve)
    l = Line(x1, y1, x2, y2)
    indent_start!(l, _node_radius(shape1, size1, l.α))
    outdent_end!(l, _node_radius(shape2, size2, l.α + pi))
    x1_1, y1_1, x1_, y1_, x1_2, y1_2 = start_offset_points(l, width)
    x2_, y2_ = end_point(l)
    move_to(context, x1_1, y1_1)
    line_to(context, x2_, y2_)
    line_to(context, x1_2, y1_2)
    if width > 2
        arc(context, x1_, y1_, width, l.α + PI_2, l.α - PI_2)
    else
        close_path(context)
    end
    set_source_rgba(context, color..., opacity)
    fill(context)
end

function draw_edge_tapered_curved!(context::CairoContext, directed,
                    x1, y1, shape1, size1,
                    x2, y2, shape2, size2,
                    width, color, opacity, curve)
    a = Arc(x1, y1, x2, y2, curve)
    geom_length(a) > sqrt(size1) + sqrt(size2) || return    
    α = start_angle(a)
    indent_start!(a, _node_radius(shape1, size1, α))
    outdent_end!(a, _node_radius(shape2, size2, end_angle(a)))
    x1_1, y1_1, x1_, y1_, x1_2, y1_2 = start_offset_points(a, width)
    x2_, y2_ = end_point(a)
    outline!(context, Arc(x1_1, y1_1, x2_, y2_, curve))
    outline!(context, Arc(x2_, y2_, x1_2, y1_2, -curve))
    if width > 2
        arc(context, x1_, y1_, width, α + PI_2, α - PI_2)
    else
        close_path(context)
    end
    set_source_rgba(context, color..., opacity)
    fill(context)
end

function draw_edge_tapered_selfloop!(context::CairoContext, directed,
                    x1, y1, shape1, size1,
                    x2, y2, shape2, size2,
                    width, color, opacity, curve)
    curve = curve > 0 ? 1.2 : -1.2
    α = curve > 0 ? -PI_2 : PI_2
    r1 = _node_radius(shape1, size1, α - curve)
    width > r1 && return
    r2 = _node_radius(shape1, size1, α + curve)
    x1_, y1_ = end_point(Line(float(x1), float(y1), α - curve, 0., r1))
    x2_, y2_ = end_point(Line(float(x1), float(y1), α + curve, 0., r2))
    outline!(context, Arc(x1_ - width, y1_, x2_, y2_, curve))
    outline!(context, Arc(x2_, y2_, x1_ + width, y1_, -curve))
    if width > 1
        if curve > 0
            arc(context, x1_, y1_, width, 0, pi)
        else
            arc_negative(context, x1_, y1_, width, 0, pi)
        end
    else
        close_path(context)
    end
    set_source_rgba(context, color..., opacity)
    fill(context)
end
