List = require("../list").List


# The world is essentially a collection of the bodies that interact with
# each other
exports.World = class World
	constructor: ->
		@bodies = new List

	add: (body) ->
		# The body needs a back reference to the world
		# @TODO: Is there a better solution?
		body.world = @

		@bodies.add body

		return this
