Action = require("./action").Action
Move = require("./move").Move


exports.Charge = class Charge extends Action
	vx: 0

	constructor: (@player, @vx) ->
		super arguments...

	can: -> not @player.chargeI.active

	compensate: (delay) ->
		return if not @player.moveI.active

		# Max delay compensation of 100ms
		delay = 100 if delay > 100

		console.log "compensating", delay

		compensationV = Move.compensateMove(
			delay
			@player.moveI
			y: 0, x: @vx
		)

		@player.x += compensationV.x
		@player.y += compensationV.y

	perform: (delay) ->
		startCharge = =>
			@player.moveI.disable()
			@player.chargeI.enable()

			@player.chargeI.x = @vx

		stopCharge = =>
			@player.chargeI.disable()
			@player.moveI.enable()

		# @TODO: Stop charge after running into something
		# @TODO: Charge only once per airborne

		# Set the current direction if moving
		@player.set(direction: 1) if @vx > 0
		@player.set(direction: -1) if @vx < 0

		# Compensate for delay
		@compensate delay

		@player.bindNextTickIn 250, (time, dt) ->
			stopCharge()

		# Start the charge
		startCharge()


exports.ChargeLeft = class ChargeLeft extends Charge
	id: 0x04

	constructor: (@player) ->
		super @player, -@player.speed * 4


exports.ChargeRight = class ChargeRight extends Charge
	id: 0x05

	constructor: (@player) ->
		super @player, @player.speed * 4
