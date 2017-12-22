## Plotting networks with Cairo ##

# TODO: eliminate intermediate layers when passing styles
# TODO: ensure no mixed type combinations when calling Cairo
# TODO: introduce color maps for real-valued attributes
# TODO: draw parallel edges gracefully, like in graph-tool

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

function _setup_layout(surface::CairoSurface, g::Graph, layout, margin, zoom)
    if haskey(g.nodeattrs, :x) && haskey(g.nodeattrs, :y)   # get layout
        x_ = g.nodeattrs[:x]
        y_ = g.nodeattrs[:y]
    elseif length(layout) >= 2
        x_, y_ = layout[1:2]
    else
        if nodecount(g) <= 1000
            x_, y_ = layout_fruchterman_reingold(g)
        else
            x_, y_ = layout_circle(g)
        end
    end
    if isa(margin, Real)                            # get margins
        m_x = m_y = margin
    elseif typeof(margin) <: Tuple{Real,Real}
        m_x, m_y = margin
    else
        error("invalid margin specification")
    end
    x = _rescale_coord(x_, surface.width / zoom, m_x / zoom)      # rescale x and y
    y = _rescale_coord(y_, surface.height / zoom, m_y / zoom)
    return x, y
end

function _setup_node_style(g::Graph; kvargs...)
    style = Dict{Symbol,Any}(       # default node style
        :shape          => ConstantAttribute(:circle),
        :size           => ConstantAttribute(100),
        :color          => ConstantAttribute((.7,.1,.2)),
        :border_color   => ConstantAttribute((1.,1.,1.)),
        :border_width   => ConstantAttribute(.5),
        :opacity        => ConstantAttribute(.8),
        :label          => ConstantAttribute(""),
        :label_color    => ConstantAttribute((0.,0.,0.))
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
        :shape          => ConstantAttribute(:arrow),
        :width          => ConstantAttribute(.5),
        :color          => ConstantAttribute((.5,.5,.5)),
        :opacity        => ConstantAttribute(.8),
        :curve          => ConstantAttribute(0)
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


function draw_background!(context::CairoContext;
                          bg_color=(1.,1.,1.),
                          bg_opacity=1,
                          kvargs...)
    set_source_rgba(context, _color(bg_color)..., bg_opacity)
    paint(context)
end


function draw_node!(context::CairoContext, x, y, shape, size, color, bcolor, bwidth, opacity)
    side = sqrt(size)
    outline_node!(Val{shape}, context, x, y, side)
    set_source_rgba(context, color..., opacity)
    bwidth == 0 && return fill(context)
    fill_preserve(context)
    set_source_rgba(context, bcolor..., opacity)
    set_line_width(context, bwidth)
    stroke(context)
end

function draw_nodes!(context::CairoContext, g::Graph, x, y, nodestyle)
    shape, size, color, opacity, border_color, border_width =
        nodestyle[:shape], nodestyle[:size], nodestyle[:color], nodestyle[:opacity],
        nodestyle[:border_color], nodestyle[:border_width]
    for i = nodes(g)
        draw_node!(context, x[i], y[i],
                   shape[i], size[i], _color(color[i]),
                   _color(border_color[i]), border_width[i], opacity[i])
    end
end

function draw_node_labels!(context::CairoContext, g::Graph, x, y, nodestyle)
    size, label, label_color, opacity = nodestyle[:size],
        nodestyle[:label], nodestyle[:label_color], nodestyle[:opacity]
    select_font_face(context, "Sans", 0, 0)  # TODO: make font face user-selectable
    for i = nodes(g)
        l = string(label[i])
        l == "" && continue
        set_font_size(context, sqrt(size[i]) * .8)  # TODO: make font size user-selectable
        ext = text_extents(context, l)
        move_to(context, x[i] - ext[3] / 2 - ext[1],
                         y[i] - ext[4] / 2 - ext[2])
        set_source_rgba(context, _color(label_color[i])..., opacity[i])
        show_text(context, l)
    end
end


function draw_edges!(context::CairoContext, g::Graph, x, y, nodestyle, edgestyle)
    shape, size = nodestyle[:shape], nodestyle[:size]
    eshape, width, color, opacity, curve = edgestyle[:shape],
        edgestyle[:width], edgestyle[:color], edgestyle[:opacity], edgestyle[:curve]
    for e = edges(g)
        s = eshape[e.id]
        c = clamp(curve[e.id], -1.5, 1.5)
        if s == :line
            f = draw_edge_line!
        elseif s == :arrow
            if e.source == e.target
                f = draw_edge_arrow_selfloop!
            elseif abs(c) < .05
                f = draw_edge_arrow_straight!
            else
                f = draw_edge_arrow_curved!
            end
        elseif s == :tapered
            if e.source == e.target
                f = draw_edge_tapered_selfloop!
            elseif abs(c) < .05
                f = draw_edge_tapered_straight!
            else
                f = draw_edge_tapered_curved!
            end
        else
            continue
        end
        f(context, e.isdir,
            x[e.source], y[e.source], shape[e.source], size[e.source],
            x[e.target], y[e.target], shape[e.target], size[e.target],
            width[e.id], _color(color[e.id]), opacity[e.id], c)
    end
end


function draw_graph!(surface::CairoSurface, g::Graph;
                     layout=(),
                     _layout=(),  # FIXME: remove this hack
                     margin=(20,20),
                     zoom=1,
                     kvargs...)
    context = CairoContext(surface)
    # Draw background
    draw_background!(context; kvargs...)
    nodecount(g) == 0 && return
    # Set up the layout and styles
    zoom != 1 && scale(context, zoom, zoom)
    if _layout != ()
        x, y = _layout
    else
        x, y = _setup_layout(surface, g, layout, margin, zoom)
    end
    ns = _setup_node_style(g; kvargs...)
    es = _setup_edge_style(g; kvargs...)
    # Draw the edges
    draw_edges!(context, g, x, y, ns, es)
    # Draw the nodes
    draw_nodes!(context, g, x, y, ns)
    draw_node_labels!(context, g, x, y, ns)
end


"""
    plot(g::Graph[, filename, size, format[, kvargs...]])

Plot the graph `g`. Specify the `filename`, `size`, `format`, or many
of the other parameters.
"""
function plot(g::Graph; filename="", size=(400,400), format=:svg, kvargs...)
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
    elseif format == :eps
        @assert(filename != "", "need a file name to write EPS")
        surface = CairoEPSSurface(filename, size...)
        draw_graph!(surface, g; kvargs...)
        finish(surface)
    else:
        error("wrong or unsupported image format :$format")
    end
end
