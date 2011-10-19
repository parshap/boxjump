exports.Action = class Action
	id: null

	constructor: (@player, args...) ->
		@arguments = args

	can: -> true

	predictCan: -> @can()

	# Schedule to perform the action requested at the given time
	# `delay` is how late we are to schedule the action
	schedule: (requestTime, delay) ->

	# Schedule to perform the proxied action that has occured at performTime
	scheduleProxy: (performTime) ->

	# Performs the action
	# `delay` is how late we are to perform the action
	perform: (delay) ->

	# Performs a proxied action
	# `delay` is how late we are to perform the action
	proxy: (delay) ->

	# Predicts the outcome of the action being requested
	predict: ->
