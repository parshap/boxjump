Rect = require("../physics/rect").Rect
Vector = require("../physics/vector").Vector
Model = require("../model").Model
List = require("../list").List


exports.Player = class Player extends Model
	actions:
		0x00: require("./actions/move").MoveNone
		0x01: require("./actions/move").MoveLeft
		0x02: require("./actions/move").MoveRight

		0x03: require("./actions/jump").Jump

		0x04: require("./actions/charge").ChargeLeft
		0x05: require("./actions/charge").ChargeRight

		0x10: require("./actions/punch").Punch

	speed: 10

	jump: 14

	inputDelay: 0

	defaults:
		width: 1.5
		height: 2

		x: 10
		y: 0

		health: 100

		direction: 1 # 1 = right, -1 = left

	initialize: ->
		# Create a body for this player
		@body = new Rect(
			@get("x")
			@get("y")
			@get("width")
			@get("height")
		)

		@body.fallAffinity = 2

		# Give the body a back reference to this player
		# @TODO: Is there a way to avoid this?
		# @TODO: Circular references need to be manually cleaned up
		@body.player = @

		# Collide with everything (@TODO ?)
		@body.collides -> true

		# No contact constraint between players
		@body.contacts (body) ->
			return ! body.player

		# @TODO: The body probably needs a back reference to this player

		# Create an impulse effect that will be used for movement
		@moveI = @body.impulse x: 0, y: 0

		# Create an impulse effect that will be used for charging
		@chargeI = @body.impulse(x: 0, y: 0).disable()

		@_initializeTicks()
		@_initializeCooldowns()

	# ## Bind On Tick

	_initializeTicks: ->
		@bind "tick", (time, dt) =>
			callbacks = @_callbacks["tick.next"] or []
			@_callbacks["tick.next"] = []

			callback.apply(null, arguments) for callback in callbacks

		@_tickInCallbacks = []
		@_tickAfterCallbacks = []

		@bind "tick", (time, dt) =>
			# Tick In callbacks
			inCallbacks = @_tickInCallbacks
			@_tickInCallbacks = []

			for [cbInTime, callback] in inCallbacks
				cbInTime -= dt * 1000

				if cbInTime <= 0
					callback.call(null, time, dt, -cbInTime)
				else
					# Schedule for later
					@bindNextTickIn cbInTime, callback

			# Tick After callbacks
			afterCallbacks = @_tickAfterCallbacks
			@_tickAfterCallbacks = []

			for [cbTime, callback] in afterCallbacks
				delay = time - cbTime

				if delay >= 0
					callback.call(null, time, dt, delay)
				else
					# Schedule for later
					@bindNextTickAfter cbTime, callback

	bindNextTick: (callback) ->
		@_tickInCallbacks.push [0, callback]

	bindNextTickAfter: (time, callback) ->
		@_tickAfterCallbacks.push [time, callback]

	bindNextTickIn: (inTime, callback) ->
		@_tickInCallbacks.push [inTime, callback]

	# ## Cooldowns

	_cooldowns: null

	_initializeCooldowns: ->
		@_cooldowns = {}

		@bind "tick", (time, dt) =>
			for name, value of @_cooldowns
				@_cooldowns[name] -= dt

	cooldown: (name="global", value) ->
		# Getter
		if not value
			return !! @_cooldowns[name]

		# Setter
		else if not @_cooldown[name] or @_cooldowns[name] < value
			@_cooldowns[name] = value

	# ## Actions

	predictAction: (action) ->
		action.predict()

		@trigger "predict-action", action

	proxyAction: (time, action, performTime) ->
		performTime = action.scheduleProxy time, performTime

		# @TODO: On-tick-after (performTime - ticktime/2) ?
		@bindNextTickAfter performTime, (time, dt) =>
			action.proxy (time - performTime)

			@trigger "action", action

		@trigger "schedule-action", action, performTime

	requestAction: (time, action, requestTime, delay) ->
		performTime = action.schedule time, requestTime, delay

		# @TODO: On-tick-after (performTime - ticktime/2) ?
		@bindNextTickAfter performTime, (time, dt) =>
			@performAction action, (time - performTime)

		@trigger "schedule-action", action, performTime

	performAction: (action, delay) ->
		action.perform delay

		@trigger "action", action

	tick: (time, dt) ->
		@trigger "tick", time, dt

		@body.tick time, dt


exports.PlayerList = class PlayerList extends List
