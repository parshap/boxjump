Vector = require("../../physics/vector").Vector
Action = require("./action").Action


exports.Move = class Move extends Action
	# Performs the move
	move: (vx, delay) ->
		# Set the current direction if moving
		@player.set(direction: 1) if vx > 0
		@player.set(direction: -1) if vx < 0

		# Max delay compensation of 100ms
		delay = 100 if delay > 100

		compensationV = new Vector
		compensationV.add @player.moveI.clone().mul(delay / 1000)

		@player.moveI.x = vx

		compensationV.add @player.moveI.clone().mul(delay / 1000)

		@player.x -= compensationV.x
		@player.y -= compensationV.y


exports.MoveNone = class MoveNone extends Move
	id: 0x00

	perform: (delay) ->
		@move 0, delay


exports.MoveLeft = class MoveLeft extends Move
	id: 0x01

	perform: (delay) ->
		@move -@player.speed, delay


exports.MoveRight = class MoveRight extends Move
	id: 0x02

	perform: (delay) ->
		@move @player.speed, delay
