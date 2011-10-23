Action = require("./action").Action
Move = require("./move").Move


exports.Charge = class Charge extends Action
	vx: 0

	constructor: (@player, @vx) ->
		super @player

	can: -> not @player.chargeI.active

	compensateStart: (delay) ->
		# Max delay compensation of 100ms
		delay = 20 if delay > 20

		console.log "compensating charge start", delay

		oldVelocity = if @player.moveI.active then @player.moveI else x: 0,  y: 0

		compensationV = Move.compensateMove(
			delay
			oldVelocity
			{ y: 0, x: @vx }
		)

		@player.body.x += compensationV.x
		@player.body.y += compensationV.y

	compensateStop: (delay) ->
		# Max delay compensation of 20
		delay = 20 if delay > 20

		console.log "compensating charge stop", delay

		compensationV = Move.compensateMove(
			delay
			{ y: 0, x: @player.body.velocity.x }
			{ y: 0, x: 0 }
		)

		@player.body.x += compensationV.x
		@player.body.y += compensationV.y

	perform: (delay) ->
		startCharge = (delay) =>
			# Compensate for delay
			@compensateStart delay

			@player.moveI.disable()

			@player.body.velocity.x = @vx

		stopCharge = (delay) =>
			# Compensate for delay
			@compensateStop delay

			@player.moveI.enable()

			@player.body.velocity.x = 0

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
