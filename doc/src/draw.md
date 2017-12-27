# Drawing

```@setup *
using Junet
srand(4)
```

Junet has state-of-the-art capabilities for drawing networks. It allows to control virtually every aspect of the drawing and, if need be, you can hack it even further.


## `plot()`

Similar to other Julia packages, Junet implements `plot` function to display networks.

```@docs
plot
```

!!! note
    If you are using other libraries that implement `plot()` function such as Plots, there may be warnings about name clashes. To avoid them, you can do `import Plots` instead of `using Plots`. Or you can just ignore the warnings and use functions prefixed with modules, such as `Junet.plot()` and `Plots.plot()`.



## Node style

All arguments controlling appearance of the nodes start with `node_`.

### `node_shape`

Shape of a node. The possible values are: `:circle`, `:square`, `:diamond`, `:triangle`, `:hexagon`, `:octagon`, `:none`.

```@example *
shapes = [:circle, :square, :diamond, :triangle, :hexagon, :octagon, :none]
g = Graph(nodecount=length(shapes))
plot(g, node_shape=shapes, node_label=shapes,
     layout=layout_line(g), zoom=2,
     filename="images/node_shapes.svg", size=(500, 100))
nothing  # hide
```
![](images/node_shapes.svg)


### `node_color`

Color of a node. Can be set as a 3-tuple with color channel (R, G, B) intensities or a string with CSS-compliant color specification.

```@example *
g = graph_grid(3, 3)
colors = ["red", "#00ff00", (0., 0., 1.)]
plot(g, node_color=colors[rand(1:3, nodecount(g))],
     filename="images/node_colors.svg", size=(120, 120))
nothing  # hide
```
![](images/node_colors.svg)


### `node_opacity`

Opacity of a node:
* `1` — fully opaque node
* `0.8` — default
* `0` — fully transparent node

```@example *
g = graph_grid(3, 3)
plot(g, node_opacity=rand(nodecount(g)),
     filename="images/node_opacities.svg", size=(120, 120))
nothing  # hide
```
![](images/node_opacities.svg)



### `node_size`

Size of a node.

```@example *
g = graph_grid(3, 3)
plot(g, node_size=500rand(nodecount(g)),
     filename="images/node_sizes.svg", size=(120, 120))
nothing  # hide
```
![](images/node_sizes.svg)



### `node_label`

Label of a node. If non-string is passed, it is converted to `String`.

```@example *
g = graph_grid(3, 3)
plot(g, node_label=nodes(g),
     filename="images/node_labels.svg", size=(120, 120))
nothing  # hide
```
![](images/node_labels.svg)


### `node_label_color`







## Edge style

All arguments controlling appearance of the edges start with `edge_`.

### `edge_shape`

Shape of an edge. There are 3 possible values:
* `:line` — simple straight line without any decorations. Supports the least features, but is the fastest do draw and smallest to store. Use it for big networks or if the file size matters.
* `:arrow` (default) — line with an arrowhead. Usable in most cases.
* `:tapered` — line that changes from thick at the base to thin at the end. Looks beautiful but can lead to long drawing times and large file sizes.

```@example *
shapes = [:line, :arrow, :tapered]
for shape = shapes
    plot(graph_wheel(6), edge_shape=shape,
        filename="images/edge_shape_$shape.svg", size=(100, 100))
end
```
![](images/edge_shape_line.svg)
![](images/edge_shape_arrow.svg)
![](images/edge_shape_tapered.svg)


### `edge_curve`

Curvature of an edge:
* `1` — clockwise semicircle
* `0` — straight line (default)
* `-1` — counter-clockwise semicircle

```@example *
g = graph_star(6)
for curve = -1:0.5:1
    plot(g, edge_curve=curve,
        filename="images/edge_curve_$curve.svg", size=(100, 100))
end
```
![](images/edge_curve_-1.0.svg)
![](images/edge_curve_-0.5.svg)
![](images/edge_curve_0.0.svg)
![](images/edge_curve_0.5.svg)
![](images/edge_curve_1.0.svg)


### `edge_color`

Color of an edge.

```@example *
g = graph_grid(3, 3)
colors = ["red", "#00ff00", (0., 0., 1.)]
plot(g, edge_color=colors[rand(1:3, edgecount(g))], node_color="grey",
     filename="images/edge_colors.svg", size=(120, 120))
nothing  # hide
```
![](images/edge_colors.svg)


### `edge_width`

Width of an edge.

```@example *
g = graph_grid(3, 3)
plot(g, edge_width=5rand(edgecount(g)),
     filename="images/edge_widths.svg", size=(120, 120))
nothing  # hide
```
![](images/edge_widths.svg)


## Plot style



## Overriding methods


