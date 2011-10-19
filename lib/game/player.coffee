Rect = require("../physics/rect").Rect
Vector = require("../physics/vector").Vector
Model = require("../model").Model
List = require("../list").List


exports.Player = class Player extends Model
	actions:
		0x03: require("./actions/jump").Jump

	speed: 10

	jump: 14

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

	_initializeTicks: ->
		@bind "tick", (time, dt) =>
			callbacks = @_callbacks["tick.next"] or []
			@_callbacks["tick.next"] = []

			callback.apply(null, arguments) for callback in callbacks

		@_tickCallbacks = []

		@bind "tick", (time, dt) =>
			tickCallbacks = @_tickCallbacks
			@_tickCallbacks = []

			for [cbTime, callback] in tickCallbacks
				if time > cbTime
					callback.apply(null, arguments)
				else
					# Schedule for later
					@bindNextTickAfter cbTime, callback

	bindNextTick: (callback) ->
		@_tickCallbacks.push [0, callback]

	bindNextTickAfter: (time, callback) ->
		@_tickCallbacks.push [time, callback]

	performMove: (delay, vx) ->
		if delay < -10
			@bind "tick.next", (time, dt) =>
				@performMove delay + (dt * 1000), vx

			return

		# Set the current direction if moving
		@set(direction: 1) if vx > 0
		@set(direction: -1) if vx < 0

		# Max delay compensation of 100ms
		delay = 100 if delay > 100

		compensationV = new Vector
		compensationV.add @moveI.clone().mul(delay / 1000)

		@moveI.x = vx

		compensationV.add @moveI.clone().mul(delay / 1000)

		@x -= compensationV.x
		@y -= compensationV.y

	# Charge
	canPerformCharge: -> not @chargeI.active

	performCharge: (time, delay, direction) ->
		startCharge = =>
			@moveI.disable()
			@chargeI.enable()

			@chargeI.x = @speed * 4 * direction

		stopCharge = =>
			@chargeI.disable()
			@moveI.enable()

		# @TODO: Stop charge after running into something
		# @TODO: Charge only once per airborne

		@bindNextTick (time, dt) =>
			@bindNextTickAfter time + 250, (time, dt) ->
				stopCharge()

			# Start the charge
			startCharge()

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
