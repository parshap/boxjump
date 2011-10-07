Vector = require("./vector").Vector
Body = require("./body").Body

exports.Rect = class Rect extends Body
	constructor: (x, y, @w = 0, @h = 0) ->
		super x, y

	sides: ->
		return _sides @x, @y, @w / 2, @h / 2

	# Returns whether or not this body is colliding with the given body
	colliding: (body) ->
		if body not instanceof Rect
			throw "Can't check collision against given body"

		return _colliding @sides(), body.sides()

	# Returns a movement vector to resolve the contact constraint against
	# the given body caused by the move from the given old position
	resolve: (body, oldPosition) ->
		if body not instanceof Rect
			throw "Can't check collision against given body"

		# Create the arguments needed for _resolve
		# rect1 = this body at the old position
		# rect2 = the contacting body
		# v = the movement vector causing the contact
		rect1 = _sides oldPosition.x, oldPosition.y, @w / 2, @h / 2
		rect2 = body.sides()
		moveV = new Vector({ @x, @y }).sub oldPosition

		# _resolve will return a new movement vector that would not cause
		# the contact by rect1
		resolvedV = _resolve rect1, rect2, moveV

		# We will return the movement needed to correct the existing
		# contact
		return resolvedV.sub moveV


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
			new Vector x: v.x, y: rect2.bottom - sides1.top
	else # Collision on x axis
		if v.x > 0
			new Vector x: rect2.left - rect1.right, y: v.y
		else
			new Vector x: rect2.right - rect1.left, y: v.y
