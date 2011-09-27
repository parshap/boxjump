G = window.G

G.Physics = {}

class G.Physics.Object extends G.Event
	constructor: (@x = 0, @y = 0) ->
		super()

	move: ({x, y}) ->
		@x += x
		@y += y

		return this


# AABB
class G.Physics.Rect extends G.Physics.Object
	constructor: (x, y, @width, @height) ->
		super x, y

	translate: ({x, y}) ->
		return new G.Physics.Rect @x + x, @y + y, @width, @height

	sides: ->
		hwidth = @width/2
		hheight = @height/2

		return {
			left: @x - hwidth
			right: @x + hwidth
			top: @y - hheight
			bottom: @y + hheight
		}

	colliding: (objects) ->
		collided = []
		sides = @sides()

		overlaps = (other) ->
			osides = other.sides()

			return ! (
				sides.left >= osides.right or
				sides.top >= osides.bottom or
				sides.right <= osides.left or
				sides.bottom <= osides.top
			)

		for other in objects
			collided.push other if overlaps other

		return collided

	resolve: (v, object) ->
		# No movement
		if v.x == 0 and v.y == 0
			return x: 0, y: 0

		sides1 = @sides()
		sides2 = object.sides()

		# Simple cases if movement is only along one axis
		if v.x == 0
			return if v.y > 0
				x: 0, y: sides2.top - sides1.bottom
			else
				x: 0, y: sides2.bottom - sides1.top

		if v.y == 0
			return if v.x > 0
				x: sides2.left - sides1.right, y: 0
			else
				x: sides2.right - sides1.left, y: 0

		p1 =
			x: if v.x > 0 then sides1.right else sides1.left
			y: if v.y > 0 then sides1.bottom else sides1.top
		p2 =
			x: if v.x > 0 then sides2.left else sides2.right
			y: if v.y > 0 then sides2.top else sides2.bottom

		m = Math.abs((p2.y - p1.y) / (p2.x - p1.x))
		mv = Math.abs(v.y / v.x)

		return if mv > m # Collision on y axis
			if v.y > 0
				x: v.x, y: sides2.top - sides1.bottom
			else
				x: v.x, y: sides2.bottom - sides1.top
		else # Collision on x axis
			if v.x > 0
				x: sides2.left - sides1.right, y: v.y
			else
				x: sides2.right - sides1.left, y: v.y
