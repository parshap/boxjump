Rect = require("../physics/rect").Rect
Vector = require("../physics/vector").Vector
Model = require("../model").Model
List = require("../list").List
Effect = require("../physics/effect").Effect

class PlayerBody extends Rect
	constructor: ->
		super

		@on "collide", (body, desired) =>
			desired.set @resolve body, desired

		# @TODO body needs to keep track of this "effect" for net code
		@moving = new MoveEffect @

class MoveEffect extends Effect
	velocity: null
	constructor: (@body) ->
		@velocity = Vector.zero()
		super(
			=> @body.impulse.add @velocity
			=> @body.impulse.sub @velocity
		)

	set: (velocity) ->
		oldVelocity = @velocity
		@velocity = velocity
		if @enabled
			diff = new Vector(@velocity).sub oldVelocity
			@body.impulse.add diff
			@body.trigger "effect"

exports.Player = class Player extends Model
	actions:
		0x00: require("./actions/move").MoveNone
		0x01: require("./actions/move").MoveLeft
		0x02: require("./actions/move").MoveRight

		0x03: require("./actions/jump").Jump

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
		@body = new PlayerBody(
			new Vector x: @get("x"), y: @get("y")
			new Vector x: @get("width") / 2, y: @get("height") / 2
		)

		@body.fallAffinity = 2

		# Give the body a back reference to this player
		# @TODO: Is there a way to avoid this?
		@body.player = @

		@_initializeTicks()
		@_initializeCooldowns()

	# ## Bind On Tick

	_tickCallbacks: null

	_initializeTicks: ->
		@_tickCallbacks = []

		@bind "tick", (time, dt) =>
			callbacks = @_tickCallbacks
			@_tickCallbacks = []

			for [cbTime, callback] in callbacks
				delay = time - cbTime

				if delay >= 0
					callback.call(null, time, dt, delay)
				else
					# Schedule for later
					@bindNextTickAfter cbTime, callback

	bindNextTick: (callback) ->
		@_tickCallbacks.push [0, callback]

	bindNextTickAfter: (time, callback) ->
		@_tickCallbacks.push [time, callback]

	# ## Cooldowns

	_cooldowns: null

	_initializeCooldowns: ->
		@_cooldowns = {}

		@bind "tick", (time, dt) =>
			for name, value of @_cooldowns
				@_cooldowns[name] -= dt

	onCooldown: (name="global", time=null) ->
		if not time?
			time = @game.time

		return @_cooldowns[name]? and @_cooldowns[name] >= time

	setCooldown: (nameOrGlobalTime, time=null, forceSet=false) ->
		if time?
			name = nameOrGlobalTime
		else
			name = "global"
			time = nameOrGlobalTime

		if not forceSet or not @_cooldowns[name]? or @_cooldowns[name] < time
			@_cooldowns[name] = time

	# ## Actions

	# Predict the results of the player performing the action
	# This is called as a action packet is sent to the server for the action
	# to be performed.
	predictAction: (action) ->
		action.predict()

		@trigger "predict-action", action

	# Called by the client to perform the side effects of an action that has
	# occured
	proxyAction: (time, action, performTime) ->
		performTime = action.scheduleProxy time, performTime

		# @TODO: On-tick-after (performTime - ticktime/2) ?
		@bindNextTickAfter performTime, (time, dt) =>
			action.proxy (time - performTime)

			@trigger "action", action

		@trigger "schedule-action", action, performTime

	# Called by the server when a player has performed an action
	requestAction: (time, action, requestTime, delay) ->
		performTime = action.schedule time, requestTime, delay

		# @TODO: On-tick-after (performTime - ticktime/2) ?
		@bindNextTickAfter performTime, (time, dt) =>
			@performAction action, (time - performTime)

		@trigger "schedule-action", action, performTime

	performAction: (action, delay=0) ->
		action.perform delay

		@trigger "action", action

	tick: (time, dt) ->
		@trigger "tick", time, dt

		@body.tick time, dt

exports.PlayerList = class PlayerList extends List
	getBodies: -> @map (player) -> player.body
