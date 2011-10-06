# 2d Vector
# All operations are inline except for `clone` (obviously)
exports.Vector = class Vector
	@zero: -> return new @

	constructor: ({@x, @y} = {x: 0, y: 0}) ->

	add: ({x, y}) ->
		@x += x
		@y += y
		return this

	sub: ({x, y}) ->
		@x -= x
		@y -= y
		return this

	mul: (k) ->
		x *= k
		y *= k
		return this

	div: (k) ->
		x /= k
		y /= k

	negate: -> return @mul -1

	normalize: -> return @div @length

	clone: -> return new @constructor x: @x, y: @y

	equals: ({x, y}) ->	return @x == x and @y == y

	length: -> return Math.sqrt @x * @x + @y * @y

	dot: ({x, y}) -> return @x * x + @y * y

	slope: -> return @y / @x

	toString: -> return "<#{@x},#{@y}>"
