window.G = G = {}

G.Physics = {}

G.Physics.Collision =
	collide: (o, v, elements = []) ->
		collided = []

		om = o.translate(v)
		omsides = om.sides()

		overlaps = (other) ->
			sides = other.sides()

			return ! (
				omsides.left > sides.right or
				omsides.top > sides.bottom or #
				omsides.right < sides.left or
				omsides.bottom < sides.top
			)

		for other in elements
			if overlaps other
				collided.push other
				break

		return collided

	resolve: (element1, move, elements = []) ->
		# A collision occured, resolve the position of element1
		sides = element2.sides()

		return {
			x: if move.x > 0 then sides.left else sides.right
			y: if y.x > 0 then sides.top else sides.bottom
		}

		# No collision
		return false


class G.Physics.Shape
	constructor: (@x = 0, @y = 0) ->
		@world = null

	move: (x, y) ->
		(_move = (x, y) ->
			# Calculate the movement vector
			vmove =
				x: x - @x
				y: y - @y

			collided = G.Physics.Collision.collide this, vmove, world?.elements

			for element in (@world?.elements || [])
				if result = @collide element
					collided.push element
					_move result.x, result.y
		) x, y

# AABB
class G.Physics.Rect extends G.Physics.Shape
	@fromPoints: ({x: x1, y: y1}, {x: x2, y: y2}) ->
		return new G.Physics.Rect(
			Math.abs(x2 - x1)
			Math.abs(y2 - y1)
			(x1 + x2) / 2
			(y1 + y2) / 2
		)

	constructor: (@width, @height, x, y, world) ->
		super(x, y, world)

	translate: ({x, y}) ->
		return new G.Physics.Rect @width, @height, @x + x, @y + y

	contains: ({x, y}) ->
		sides = @sides()

		return sides.left <= x <= sides.right and
			sides.top <= y <= sides.bottom

	sides: ->
		hwidth = @width/2
		hheight = @height/2

		return {
			left: @x - hwidth
			right: @x + hwidth
			top: @y - hheight
			bottom: @y + hheight
		}

	verts: ->
		sides = @sides()

		return [
			{ x: sides.right, y: sides.bottom }
			{ x: sides.left, y: sides.bottom }
			{ x: sides.left, y: sides.top }
			{ x: sides.right, y: sides.top }
		]
