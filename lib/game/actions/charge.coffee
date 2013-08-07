Action = require("./action").Action
Move = require("./move").Move


exports.Charge = class Charge extends Action
	vx: 0

	constructor: (player, @vx) ->
		super player
		@impulse = @player.body.impulse(x: @vx, y: 0).disable()

	can: -> not @impulse.active

	compensateStart: (delay) ->
		# Max delay compensation of 100ms
		delay = 20 if delay > 20

		console.log "compensating charge start", delay

		@player.body.position.add Move.compensateMove(
			delay
			@player.body.velocity
			{ y: 0, x: @vx }
		)

	compensateStop: (delay) ->
		# Max delay compensation of 20
		delay = 20 if delay > 20

		console.log "compensating charge stop", delay

		@player.body.position.add Move.compensateMove(
			delay
			new Vector x: @player.body.velocity.x, y: 0
			Vector.zero()
		)

	perform: (delay) ->
		startCharge = (delay) =>
			# Compensate for delay
			@compensateStart delay

			@player.moving.disable()
			@impulse.enable()

		stopCharge = (delay) =>
			# Compensate for delay
			@compensateStop delay

			@player.moving.enable()
			@impulse.disable()

		# @TODO: Charge only once per airborne

		# Set the current direction if moving
		@player.set(direction: 1) if @vx > 0
		@player.set(direction: -1) if @vx < 0

		stopTime = @player.game.time + 250 - delay
		@player.bindNextTickAfter stopTime, (time, dt, delay) ->
			stopCharge delay

		# Start the charge
		startCharge delay


exports.ChargeLeft = class ChargeLeft extends Charge
	id: 0x04

	constructor: (@player) ->
		super @player, -@player.speed * 4


exports.ChargeRight = class ChargeRight extends Charge
	id: 0x05

	constructor: (@player) ->
		super @player, @player.speed * 4
