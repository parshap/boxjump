Vector = require("./vector").Vector
Body = require("./body").Body

exports.Rect = class Rect extends Body
	constructor: (position, @size = Vector.zero()) ->
		super position

	sides: ->
		return _sides @position.x, @position.y, @size.x, @size.y

	collide: (body, desired) ->
		if body not instanceof Rect
			throw new Error "Body must be Rect"

		newPos = @position.clone().add desired
		sides = _sides newPos.x, newPos.y, @size.x, @size.y
		if _colliding sides, body.sides()
			@trigger "collide", body, desired

	# Returns a movement vector to resolve the contact constraint against
	# the given body caused by the move from the given old position
	resolve: (body, desired) ->
		if body not instanceof Rect
			throw new Error "Body must be Rect"

		return _resolve @sides(), body.sides(), desired


# Returns the four sides of a rect with the given position and half
# dimensions
_sides = (x, y, hw, hh) ->
	return {
		left: x - hw
		right: x + hw
		top: y - hh
		bottom: y + hh
	}

# Returns whether or not the given rects are overlapping. The rects are
# an object that define the four sides of the rect.
_colliding = (rect1, rect2) ->
	return ! (
		rect1.left >= rect2.right or
		rect1.top >= rect2.bottom or
		rect1.right <= rect2.left or
		rect1.bottom <= rect2.top
	)

# Returns a corrected movement vector that would allow movement without
# collision constraint caused by rect1 moving onto rect2 by movement
# vector v
_resolve = (rect1, rect2, v) ->
	# No movement
	if v.length() == 0
		return Vector.zero()

	# Simple cases if movement is only along one axis
	if v.x == 0
		return if v.y > 0
			new Vector x: 0, y: rect2.top - rect1.bottom
		else
			new Vector x: 0, y: rect2.bottom - rect1.top

	if v.y == 0
		return if v.x > 0
			new Vector x: rect2.left - rect1.right, y: 0
		else
			new Vector x: rect2.right - rect1.left, y: 0

	p1 = new Vector
		x: if v.x > 0 then rect1.right else rect1.left
		y: if v.y > 0 then rect1.bottom else rect1.top
	p2 = new Vector
		x: if v.x > 0 then rect2.left else rect2.right
		y: if v.y > 0 then rect2.top else rect2.bottom

	m = Math.abs p2.sub(p1).slope()
	mv = Math.abs v.slope()

	return if mv > m # Collision on y axis
		if v.y > 0
			new Vector x: v.x, y: rect2.top - rect1.bottom
		else
			new Vector x: v.x, y: rect2.bottom - rect1.top
	else # Collision on x axis
		if v.x > 0
			new Vector x: rect2.left - rect1.right, y: v.y
		else
			new Vector x: rect2.right - rect1.left, y: v.y
