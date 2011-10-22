Vector = require("../../physics/vector").Vector
Action = require("./action").Action


exports.Move = class Move extends Action
	vx: 0

	@compensateMove: (delay, oldMoveI, newMoveI) ->
		v = new Vector

		v.sub oldMoveI
		v.add newMoveI

		v.mul (delay / 1000)

		return v

	constructor: (@player, @vx) ->
		super @player

	can: -> not @player.onCooldown "move"

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

	# Performs the move
	perform: (delay) ->
		# Compensate for any delay
		@compensate delay

		# Set the current direction if moving
		@player.set(direction: 1) if @vx > 0
		@player.set(direction: -1) if @vx < 0

		# Set the movement impulse vector
		@player.moveI.x = @vx


exports.MoveNone = class MoveNone extends Move
	id: 0x00

	# You can always stop
	can: -> true

	constructor: (@player) ->
		super @player, 0


exports.MoveLeft = class MoveLeft extends Move
	id: 0x01

	constructor: (@player) ->
		super @player, -@player.speed


exports.MoveRight = class MoveRight extends Move
	id: 0x02

	constructor: (@player) ->
		super @player, @player.speed
