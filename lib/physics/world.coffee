List = require("../list").List


# The world is essentially a collection of the bodies that interact with
# each other
exports.World = class World
	gravityF: null

	constructor: ->
		@bodies = new List

	add: (body) ->
		# The body needs a back reference to the world
		# @TODO: Is there a better solution?
		body.world = @

		# Add the world gravity as a force
		body.force.add @gravityF

		@bodies.add body

		return this

	remove: (body) ->
		body.world = null
		@bodies.remove body

		# @TODO: Gravity?

		return this

	# Returns a list of bodies in the world that are colliding with the
	# given body
	collidingWith: (body) ->
		bodies = []

		@bodies.forEach (otherBody) ->
			if body._collides otherBody
				console.log "checking against", otherBody
				if body.colliding otherBody
					bodies.push otherBody
					console.log "colliding against other"

		return bodies
