exports.Action = class Action
	id: null

	# Should this action be performed by proxies?
	proxy: false

	# Should this action be performed by proxies where the proxy player
	# is the "own" player?
	proxyOwnPlayer: false

	constructor: (@player, args...) ->
		@arguments = args

		@initialize()

	initialize: ->

	can: -> true

	predictCan: -> @can()

	# Schedule to perform the action requested at the given time
	# `delay` is how late we are to schedule the action
	schedule: (time, requestTime, delay) ->
		# The default is to scheduled based on the current time,
		# adjusted for delay. The client's request time is ignored, thus
		# any latency has full affect.
		return time - delay

	# Schedule to perform the proxied action that has occured at performTime
	scheduleProxy: (time, performTime) ->
		# The default is to not adjust the given perform time
		performTime

	# Performs the action
	# `delay` is how late we are to perform the action
	perform: (delay) ->

	# Performs a proxied action
	# `delay` is how late we are to perform the action
	proxy: (delay) ->

	# Predicts the outcome of the action being requested
	predict: ->
		# The default is to perform the action
		@perform 0
