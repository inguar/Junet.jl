## Plotting networks with Cairo ##

# INFO: imports of this file make up 3/4 of the overall load time (0.51278 vs 0.11367 without),
# see if it's possible to speed up the loading time

# TODO: fix drawing self-loops again
# TODO: eliminate intermediate layers when passing styles
# TODO: ensure no mixed type combinations when calling Cairo
# TODO: introduce color maps for real-valued attributes
# TODO: draw parallel edges gracefully, like in graph-tool
# TODO: in undirected graphs, draw edges along dyads from i to j, i < j


getrgb(c::Tuple{Real,Real,Real}) = c
getrgb(c::Tuple{Integer,Integer,Integer}) = (c[1] / 255, c[2] / 255, c[3] / 255)
getrgb(c::RGB) = (c.r, c.g, c.b)
getrgb(c::AbstractString) = (@_inline_meta; x = parse(RGB, c); (x.r, x.g, x.b))


function setup_layout(surface::CairoSurface, g::Graph, layout, margin, zoom)
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
    x = rescale(x_, surface.width / zoom, m_x / zoom)      # rescale x and y
    y = rescale(y_, surface.height / zoom, m_y / zoom)
    return x, y
end


function draw_background!(context::CairoContext;
                          bg_color=(1., 1., 1.),
                          bg_opacity=1,
                          kvargs...)
    set_source_rgba(context, getrgb(bg_color)..., bg_opacity)
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
                   shape[i], size[i], getrgb(color[i]),
                   getrgb(border_color[i]), border_width[i], opacity[i])
    end
end

# TODO: align text vertically by its baseline, not bounding box
# That would require enhancements to be pushed straight to Cairo.jl
function draw_node_labels!(context::CairoContext, g::Graph, x, y, nodestyle)
    size, label, label_color, border_color, opacity = nodestyle[:size], nodestyle[:label], 
        nodestyle[:label_color], nodestyle[:border_color], nodestyle[:opacity]
    select_font_face(context, "Sans", 0, 0)  # TODO: make font face user-selectable
    for i = nodes(g)
        l = string(label[i])
        l == "" && continue
        set_font_size(context, round(Int, sqrt(size[i]) * .8))  # TODO: make font size user-selectable
        ext = text_extents(context, l)
        move_to(context, x[i] - ext[3] / 2 - ext[1],
                y[i] - ext[4] / 2 - ext[2])
        text_path(context, l)
        set_source_rgba(context, getrgb(border_color[i])..., opacity[i] / 2)
        set_line_width(context, 2)
        stroke_preserve(context)
        set_source_rgba(context, getrgb(label_color[i])..., opacity[i])
        fill(context)
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
            width[e.id], getrgb(color[e.id]), opacity[e.id], c)
    end
end


function draw_graph!(surface::CairoSurface, g::Graph;
                     layout=(),
                     _layout=(),  # FIXME: remove this hack
                     margin=(20, 20),
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
        x, y = setup_layout(surface, g, layout, margin, zoom)
    end
    ns = setup_node_style(g; kvargs...)
    es = setup_edge_style(g; kvargs...)
    # Draw the edges
    draw_edges!(context, g, x, y, ns, es)
    # Draw the nodes
    draw_nodes!(context, g, x, y, ns)
    draw_node_labels!(context, g, x, y, ns)
end


"""
    plot(g::Graph[; file, format, size, kvargs...])

Plot the graph `g`. Specify the `format`, `file`, `size`, or many
of the other parameters to customize its style.
"""
function plot(g::Graph; file="", format=:auto, size=(400, 400), kvargs...)
    if format == :auto
        if file != ""
            ext = splitext(file)[2]
            if ext in (".png", ".svg", ".pdf", ".eps")
                format = Symbol(ext[2:end])
            else
                error("unknown file extension \"$ext\"; specify it or define `format` instead")
            end
        else
            format = nodecount(g) <= 1000 ? :svg : :png
        end
    end
    if format == :png
        surface = CairoARGBSurface(size...)
        draw_graph!(surface, g; kvargs...)
        if file != ""
            write_to_png(surface, file)
        else
            return surface
        end
    elseif format == :svg
        if file != ""
            surface = CairoSVGSurface(file, size...)
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
        @assert(file != "", "need a file name to write PDF")
        surface = CairoPDFSurface(file, size...)
        draw_graph!(surface, g; kvargs...)
        finish(surface)
    elseif format == :eps
        @assert(file != "", "need a file name to write EPS")
        surface = CairoEPSSurface(file, size...)
        draw_graph!(surface, g; kvargs...)
        finish(surface)
    else
        error("unknown image format :$format; choose from :png, :svg, :pdf, or :eps")
    end
end
