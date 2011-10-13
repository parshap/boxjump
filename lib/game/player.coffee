Rect = require("../physics/rect").Rect
Vector = require("../physics/vector").Vector
Model = require("../model").Model
List = require("../list").List


exports.Player = class Player extends Model
	@defineAction: (action, options) ->
		@prototype.actions[action] = options

	actions: {}

	speed: 10

	jump: 14

	defaults:
		width: 1.5
		height: 2

		x: 10
		y: 0

		health: 100

	initialize: ->
		# Create a body for this player
		@body = new Rect(
			@get("x")
			@get("y")
			@get("width")
			@get("height")
		)

		@body.fallAffinity = 1.5

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

		@_initializeTicks()

	_initializeTicks: ->
		@bind "tick", (time, dt) =>
			callbacks = @_callbacks["tick.next"] or []
			@_callbacks["tick.next"] = []

			callback.apply(null, arguments) for callback in callbacks

	performMove: (delay, vx) ->
		if delay < -10
			@bind "tick.next", (time, dt) =>
				@performMove delay + (dt * 1000), vx

			return

		delay = 100 if delay > 100

		compensationV = new Vector
		compensationV.add @moveI.clone().mul(delay / 1000)

		@moveI.x = vx

		compensationV.add @moveI.clone().mul(delay / 1000)

		@x -= compensationV.x
		@y -= compensationV.y

	# Stop Movement
	@defineAction 0x00
		can: -> true
		perform: (time, delay) ->
			@performMove delay, 0

	# Move Left
	@defineAction 0x01
		can: -> true
		perform: (time, delay) ->
			@performMove delay, -@speed

	# Move Right
	@defineAction 0x02
		can: -> true
		perform: (time, delay) ->
			@performMove delay, @speed

	# Jump
	@defineAction 0x03
		can: -> ! @body.airborne
		perform: (time, delay, power) ->
			console.log "jump called", delay
			if delay < -10
				console.log "jump scheduling"
				@bind "tick.next", (time, dt) =>
					@perform 0x03, time, delay + (dt * 1000), [power]

				return

			# Can't jump if airborne
			return if @body.airborne

			# Max 50ms delay compensation
			delay = 100 if delay > 100

			jumpV = new Vector x: 0, y: -(@jump * power)

			# @TODO: We need to compensate jumpV for gravity when "advancing"
			# the jump for delay compensation
			compensationV = jumpV.clone().mul(delay / 1000)

			console.log "Jumping", {
				delay: delay
				power: power
				compensation: compensationV
			}

			@x += compensationV.x
			@y += compensationV.y

			@body.velocity.add jumpV

	canPerform: (action, args=[]) ->
		@actions[action]?.can.call @, args...

	perform: (action, time, delay, args=[]) ->
		@actions[action].perform.call @, time, delay, args...

	predictCanPerform: (action, args=[]) ->
		(@actions[action].predictCan || @actions[action].can).call @, args...

	predictPerform: (action, args=[]) ->
		if @actions[action].predictPerform
			@actions[action].predictPerform.call @, args...
		else
			@actions[action].perform.call @, 0, 0, args...

	tick: (time, dt) ->
		@trigger "tick", time, dt

		@body.tick time, dt


exports.PlayerList = class PlayerList extends List
