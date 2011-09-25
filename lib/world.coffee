class G.Event
	bind: (event, function) ->

class G.World
	constructor: (@elements = []) ->

	add: (element) ->
		element.world = @

		@elements.push(element)

		return this

	remove: (element) ->
		element.world = null

		index = @elements.indexOf(element)
		@elements = @elements.splice(element, 1)

		return this
