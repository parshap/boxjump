# Introduction
*Elements* is a *2D physics* library written in CoffeeScript (for use in
JavaScript environments) providing *rigid body* collision detection and
resolution.

There are two basic building blocks in *Elements*: a *world* and the
*element*s it contains. A *world* is essentially a collection of
*element*s that may interact with each other (i.e., may collide).
*Element*s are geometric shapes with an *(x, y)* coordinate to define
the location of the element in the world.


# API

## Elements.World

### add(element)
Adds the given element to the world.

### remove(element)
Removes the given element from the world.


## Elements.Element

### move(x, y)
Attempts to move the element to the given *x* and *y* coordinates in the
world. If the movement causes a collision, collision resolution will be
performed. The element `move` is called in is guaranteed to be the only
element moved (as a result of the move and/or collision resolution). The
*x* and *y* attributes will be updated to reflect any movement.

### x
The x coordinate of the element's center in the world.

### y
The y coordinate of the element's center in the world.

### world
The world the element belongs to. Elements can only belong to one world
at a time.
