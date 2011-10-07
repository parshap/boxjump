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
		body.force @gravityF

		@bodies.add body

		return this
