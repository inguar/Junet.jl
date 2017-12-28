## Default node and edge style definitions ##

constattr(v) = ConstantAttribute(v, ()->1)

default_node_style() = AttributeDict(
        :shape          => constattr(:circle),
        :size           => constattr(100),
        :color          => constattr((.7, .1, .2)),
        :border_color   => constattr((1., 1., 1.)),
        :border_width   => constattr(.5),
        :opacity        => constattr(.8),
        :label          => constattr(""),
        :label_color    => constattr((0., 0., 0.)))

default_edge_style() = AttributeDict(
        :shape          => constattr(:arrow),
        :width          => constattr(.5),
        :color          => constattr((.5, .5, .5)),
        :opacity        => constattr(.8),
        :curve          => constattr(0))

function setup_node_style(g::Graph; kvargs...)
    style = default_node_style()
    for (k, v) in g.nodeattrs       # incorporate node attributes
        if haskey(style, k)
            style[k] = v
        end
    end
    for (k, v) in kvargs            # incorporate node kvargs
        ks = String(k)
        if startswith(ks, "node_")
            k_ = Symbol(ks[6:end])
            if haskey(style, k_)
                style[k_] = attribute(v, ()->1)
            end
        end
    end
    return style
end

function setup_edge_style(g::Graph; kvargs...)
    style = default_edge_style()
    for (k, v) in g.edgeattrs       # incorporate edge attributes
        if haskey(style, k)
            style[k] = v
        end
    end
    for (k, v) in kvargs            # incorporate edge kvargs
        ks = String(k)
        if startswith(ks, "edge_")
            k_ = Symbol(ks[6:end])
            if haskey(style, k_)
                style[k_] = attribute(v, ()->1)
            end
        end
    end
    return style
end
