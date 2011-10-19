Action = require("./action").Action


exports.Charge = class Charge extends Action
	# Charge
	can: -> not @player.chargeI.active

	charge: (direction, delay) ->
		startCharge = =>
			@player.moveI.disable()
			@player.chargeI.enable()

			@player.chargeI.x = @player.speed * 4 * direction

		stopCharge = =>
			@player.chargeI.disable()
			@player.moveI.enable()

		# @TODO: Stop charge after running into something
		# @TODO: Charge only once per airborne
		# @TODO: Compensate for delay (like move)

		@player.bindNextTick (time, dt) =>
			@player.bindNextTickAfter time + 250, (time, dt) ->
				stopCharge()

			# Start the charge
			startCharge()

exports.ChargeLeft = class ChargeLeft extends Charge
	id: 0x04

	perform: (delay) ->
		@charge -1, delay


exports.ChargeRight = class ChargeRight extends Charge
	id: 0x05

	perform: (delay) ->
		@charge 1, delay
