## Parameter types used by Junet for multiple dispatch ##

"""
    DirParam

Abstract parent for parameter types encoding directedness.

In Junet, all data is stored in data structures that are agnostic of graphs'
directionality. The directionality is encoded in type parameters, for which
`DirParam` provides an abstract parent type.

The interpretation of those parameter types depends on each particular type that
uses them, but there are some commonalities:
  * `Forward` means interpreting data right as it's stored, e.g., look in the
    `forward` field to find info about edges originating from a node.
  * `Reverse` is the opposite of `Forward`.
  * `Both` means to look in both directions. Typically leads to processing two
    more data than with the previous ones.

For good presentation, they have two parents — `Directed` and `Undirected`,
by the type of graphs in which they are used.
"""
abstract type DirParam end
abstract type Directed <: DirParam end
abstract type Forward  <: Directed end
abstract type Reverse  <: Directed end
abstract type Undirected <: DirParam end
abstract type Both       <: Undirected end

dir_xor(::Type{D}, ::Type{R}) where {D<:Forward, R<:Forward} = Forward
dir_xor(::Type{D}, ::Type{R}) where {D<:Forward, R<:Reverse} = Reverse
dir_xor(::Type{D}, ::Type{R}) where {D<:Reverse, R<:Forward} = Reverse
dir_xor(::Type{D}, ::Type{R}) where {D<:Reverse, R<:Reverse} = Forward
dir_xor(::Type{D}, ::Type{R}) where {D<:DirParam, R<:DirParam} = Both

"""
    MultiParam

Similar to `DirParam`, this abstract type is for encoding whether graph may
have multiple edges. There are two child types: `Multi` amd `Simple`.
"""
abstract type MultiParam end
abstract type Multi  <: MultiParam end
abstract type Simple <: MultiParam end
