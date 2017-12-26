# Graph generators

This file covers creation of the "classic" graphs.

```@docs
graph_path
```
![](images/graph_path.svg)

----

```@docs
graph_cycle
```
![](images/graph_cycle.svg)

----

```@docs
graph_star
```
![](images/graph_star.svg)

----

```@docs
graph_wheel
```
![](images/graph_wheel.svg)

----

```@docs
graph_complete
```
![](images/graph_complete.svg)

----

```@docs
graph_grid
```
![](images/graph_grid.svg)

----

```@docs
graph_web
```
![](images/graph_web.svg)

----

```@docs
graph_tree
```
![](images/graph_tree.svg)

----

```@docs
graph_random
```

----

```@docs
graph_erdos_renyi
```
![](images/graph_erdos_renyi.svg)

----

```@docs
graph_gilbert
```
![](images/graph_gilbert.svg)

----

```@docs
graph_smallworld
```
![](images/graph_smallworld.svg)



```@eval
using Junet

srand(4)

plotit(g, fname) = plot(g, format=:svg, filename="images/$fname.svg",
    size=(200, 200), zoom=.4 + 4 / nodecount(g))

plotit(graph_path(10), :graph_path)
plotit(graph_cycle(10), :graph_cycle)
plotit(graph_star(10), :graph_star)
plotit(graph_wheel(10), :graph_wheel)
plotit(graph_complete(10), :graph_complete)
plotit(graph_grid(10, 5), :graph_grid)
plotit(graph_web(4, 20), :graph_web)
plotit(graph_tree(3, 3), :graph_tree)
plotit(graph_smallworld(20, 4, .1), :graph_smallworld)

plotit(graph_erdos_renyi(100, 200), :graph_erdos_renyi)
plotit(graph_gilbert(100, .2), :graph_gilbert)

nothing
```
