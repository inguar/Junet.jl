## Plotting networks with Cairo ##

# TODO: switch to the new Tableau color scheme, maybe keep the purple color
# TODO: handle self-loops gracefully
# TODO: draw parallel edges gracefully, like in graph-tool
# TODO: fix arrow cap offset
# TODO: fix drawing short edges (arrow cap angle)
# TODO: allow variable arrow cap sizes

@inline _attribute(v::T) where {T<:AbstractVector} = v
@inline _attribute(v::T) where {T<:AbstractAttribute} = v
@inline _attribute(v::Any) = ConstantAttribute(v)

@inline _color(c::T) where {T<:Tuple{Integer, Integer, Integer}} = (c[1]/255, c[2]/255, c[3]/255)
@inline _color(c::T) where {T<:Tuple{Real, Real, Real}} = c
@inline _color(c::T) where {T<:RGB} = (c.r, c.g, c.b)
@inline _color(c::T) where {T<:AbstractString} = begin
    haskey(color_names, c) || error("unknown color \"$c\"")
    x = color_names[c]
    return (x[1]/255, x[2]/255, x[3]/255)
end

function _rescale_coord(v, newmax::Real, margin::Real)
    oldmin, oldmax = extrema(v)
    newmax -= margin * 2
    return [round(Int16, margin + (x - oldmin) / (oldmax - oldmin) * newmax) for x = v]
end

function _setup_layout(surface::CairoSurface, g::Graph, layout, margin)
    if haskey(g.nodeattrs, :x) && haskey(g.nodeattrs, :y)   # get layout
        x_ = g.nodeattrs[:x]
        y_ = g.nodeattrs[:y]
    elseif length(layout) >= 2
        x_, y_ = layout[1:2]
    else
        x_, y_ = layout_fruchterman_reingold(g)
    end
    if isa(margin, Real)                            # get margins
        m_x = m_y = margin
    elseif typeof(margin) <: Tuple{Real,Real}
        m_x, m_y = margin
    else
        error("Invalid margin specification")
    end
    x = _rescale_coord(x_, surface.width, m_x)      # rescale x and y
    y = _rescale_coord(y_, surface.height, m_y)
    return x, y
end

function _setup_node_style(g::Graph; kvargs...)
    style = Dict{Symbol,Any}(       # default node style
        :shape          => ConstantAttribute(:circle),
        :size           => ConstantAttribute(10),
        :color          => ConstantAttribute((.7,.2,.5)),
        :border_color   => ConstantAttribute((1.,1.,1.)),
        :opacity        => ConstantAttribute(.75)
    )
    for (k, v) in g.nodeattrs       # incorporate node attributes
        if haskey(style, k)
            style[k] = _attribute(v)
        end
    end
    for (k, v) in kvargs            # incorporate node kvargs
        m = match(r"(?<=node_)[a-z_]+", string(k))
        if isa(m, RegexMatch)
            k_ = Symbol(m.match)
            if haskey(style, k_)
                style[k_] = _attribute(v)
            end
        end
    end
    return style
end

function _setup_edge_style(g::Graph; kvargs...)
    style = Dict{Symbol,Any}(       # default edge style
        :width          => ConstantAttribute(.5),
        :color          => ConstantAttribute((.5,.5,.5)),
        :opacity        => ConstantAttribute(.5),
        :curved         => ConstantAttribute(0)
    )
    for (k, v) in g.edgeattrs       # incorporate edge attributes
        if haskey(style, k)
            style[k] = _attribute(v)
        end
    end
    for (k, v) in kvargs            # incorporate edge kvargs
        m = match(r"(?<=edge_)[a-z_]+", string(k))
        if isa(m, RegexMatch)
            k_ = Symbol(m.match)
            if haskey(style, k_)
                style[k_] = _attribute(v)
            end
        end
    end
    return style
end

function _node_offset(shape::Symbol, size::Real, angle::Real)
    # TODO: switch to sin and cos as arguments and collate lots of stuff together
    s, c = sin(angle), cos(angle)
    if shape == :circle
        return (size*.56 * c, size*.56 * s)
    elseif shape == :square
        if abs(s) < abs(c)
            return (size/2 * sign(c), size/2 * s/abs(c))
        else
            return (size/2 * c/abs(s), size/2 * sign(s))
        end
    elseif shape == :diamond  # FIXME, this is bogus
        if abs(s) > abs(c)
        return (size/2 * sign(c), size/2 * s/abs(c))
            end
    else
        error("unsupported shape")
    end
end

function _curve_points(x1, y1, x2, y2, angle, rotation=.5)
    offset = .3
    dist = sqrt(float(y2 - y1) ^ 2 + float(x2 - x1) ^ 2)
    return (float(x1) + dist * offset * cos(angle + rotation),
            float(y1) + dist * offset * sin(angle + rotation),
            float(x2) - dist * offset * cos(angle - rotation),
            float(y2) - dist * offset * sin(angle - rotation))
end


function draw_background!(context::CairoContext, width::Real, height::Real;
                          bg_color=(1.,1.,1.),
                          bg_opacity=1,
                          kvargs...)
    rectangle(context, 0, 0, width, height)
    set_source_rgba(context, _color(bg_color)..., bg_opacity)
    fill(context)
end


function draw_node!(context::CairoContext, x, y, shape, size, color, bcolor, opacity)
    if shape == :circle
        circle(context, x, y, size*.56)
    elseif shape == :square
        rectangle(context, x-size/2, y-size/2, size, size)
    elseif shape == :diamond
        move_to(context, x-size*.7, y)
        line_to(context, x, y-size*.7)
        line_to(context, x+size*.7, y)
        line_to(context, x, y+size*.7)
        close_path(context)
    end
    set_source_rgba(context, color..., opacity)
    fill_preserve(context)
    set_source_rgba(context, bcolor..., opacity)
    set_line_width(context, 1)
    stroke(context)
end

function draw_nodes!(context::CairoContext, g::Graph, x, y, nodestyle)
    shape, size, color, border_color, opacity =
        nodestyle[:shape], nodestyle[:size], nodestyle[:color],
        nodestyle[:border_color], nodestyle[:opacity]
    for i = nodes(g)
        draw_node!(context, x[i], y[i],
                   shape[i], size[i], _color(color[i]), _color(border_color[i]), opacity[i])
    end
end

function draw_node_labels!(context::CairoContext, g::Graph, x, y)
    haskey(g.nodeattrs, :label) || return
    label = g[:, :label]
    # select_font_face(context, "Roboto Mono")
    set_font_size(context, 10)
    for i = nodes(g)
        move_to(context, x[i], y[i])
        set_source_rgb(context, 0.1, 0.1, 0.1)
        show_text(context, label[i])
    end
end

function draw_arrow!(context::CairoContext, x, y, α, color, opacity)
    r = 5
    move_to(context, x, y)
    line_to(context, x-cos(α-.35)*r, y-sin(α-.35)*r)
    curve_to(context, x-cos(α-.1)*r*.7, y-sin(α-.1)*r*.7,
                x-cos(α+.1)*r*.7, y-sin(α+.1)*r*.7,
                x-cos(α+.35)*r, y-sin(α+.35)*r)
    close_path(context)
    set_source_rgba(context, color..., opacity)
    fill(context)
end

function draw_edge!(context::CairoContext, directed,
                    x1, y1, shape1, size1,
                    x2, y2, shape2, size2,
                    width, color, opacity, curved)
    α = atan2(y2 - y1, x2 - x1)
    if curved == 0
        Δx, Δy = _node_offset(shape1, size1, α)
        move_to(context, x1 + Δx, y1 + Δy)
        Δx, Δy = _node_offset(shape2, size2, α + pi)
        line_to(context, x2 + Δx, y2 + Δy)
        set_line_width(context, width)
        set_source_rgba(context, color..., opacity)
        stroke(context)
    else
        Δx, Δy = _node_offset(shape1, size1, α + curved)
        move_to(context, x1 + Δx, y1 + Δy)
        Δx, Δy = _node_offset(shape2, size2, α + pi - curved)
        curve_to(context, _curve_points(x1, y1, x2, y2, α, curved)..., x2 + Δx, y2 + Δy)
        set_line_width(context, width)
        set_source_rgba(context, color..., opacity)
        stroke(context)
    end
    directed && draw_arrow!(context, x2+Δx, y2+Δy, α-curved, color, opacity)
end

function draw_edges!(context::CairoContext, g::Graph, x, y, nodestyle, edgestyle)
    shape, size = nodestyle[:shape], nodestyle[:size]
    width, color, opacity, curved =
        edgestyle[:width], edgestyle[:color], edgestyle[:opacity], edgestyle[:curved]
    for e = edges(g)
        draw_edge!(context, e.isdir,
                   x[e.source], y[e.source], shape[e.source], size[e.source],
                   x[e.target], y[e.target], shape[e.target], size[e.target],
                   width[e.id], _color(color[e.id]), opacity[e.id], curved[e.id])
    end
end


function draw_graph!(surface::CairoSurface, g::Graph;
                     layout=(),
                     _layout=(),
                     margin=(20,20),
                     _scale=1,
                     kvargs...)
    context = CairoContext(surface)
    # Draw background
    draw_background!(context, surface.width, surface.height; kvargs...)
    nodecount(g) == 0 && return
    # Set up the layout and styles
    _scale != 1 && scale(context, _scale, _scale)
    if _layout != ()
        x, y = _layout
    else
        x, y = _setup_layout(surface, g, layout, margin)
    end
    ns = _setup_node_style(g; kvargs...)
    es = _setup_edge_style(g; kvargs...)
    # Draw the edges
    draw_edges!(context, g, x, y, ns, es)
    # Draw the nodes
    draw_nodes!(context, g, x, y, ns)
    draw_node_labels!(context, g, x, y)
end


"""
    plot(g::Graph[, filename, size, format[, kvargs...]])

Plot the graph `g`. Specify the `filename`, `size`, `format`, or many
of the other parameters.
"""
function plot(g::Graph, filename="", size=(500,500), format=:png; kvargs...)
    if format == :png
        surface = CairoARGBSurface(size...)
        draw_graph!(surface, g; kvargs...)
        if filename != ""
            write_to_png(surface, filename)
        else
            return surface
        end
    elseif format == :svg
        if filename != ""
            surface = CairoSVGSurface(filename, size...)
            draw_graph!(surface, g; kvargs...)
            finish(surface)
        else
            buf = IOBuffer()
            surface = CairoSVGSurface(buf, size...)
            draw_graph!(surface, g; kvargs...)
            finish(surface)
            display(MIME("image/svg+xml"), String(take!(buf)))
        end
    elseif format == :pdf
        @assert(filename != "", "need a file name to write PDF")
        surface = CairoPDFSurface(filename, size...)
        draw_graph!(surface, g; kvargs...)
        finish(surface)
    else:
        error("wrong or unsupported image format :$format")
    end
end
