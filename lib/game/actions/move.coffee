Vector = require("../../physics/vector").Vector
Action = require("./action").Action

exports.Move = class Move extends Action
	velocity: null

	@compensateMove: (delay, oldMoveI, newMoveI) ->
		v = new Vector

		v.sub oldMoveI
		v.add newMoveI

		v.mul (delay / 1000)

		return v

	constructor: (player, @velocity) ->
		super player

	can: -> not @player.onCooldown "move"

	compensate: (delay) ->
		return if delay is 0
		return if not @player.body.moving.enabled

		# Max delay compensation of 100ms
		delay = 100 if delay > 100

		console.log "compensating", delay

		@player.body.correctTo Move.compensateMove(
			delay
			@player.body.moving.velocity
			@velocity
		).add @player.body.position

	# Performs the move
	perform: (delay) ->
		# Compensate for any delay
		@compensate delay

		# Set the current direction if moving
		@player.set direction: 1 if @velocity.x > 0
		@player.set direction: -1 if @velocity.x < 0

		# Set the movement impulse vector
		@player.body.moving.set @velocity

exports.MoveNone = class MoveNone extends Move
	id: 0x00

	# You can always stop
	can: -> true

	constructor: (@player) ->
		super @player, Vector.zero()

exports.MoveLeft = class MoveLeft extends Move
	id: 0x01

	constructor: (@player) ->
		super @player, new Vector x: -@player.speed, y: 0

exports.MoveRight = class MoveRight extends Move
	id: 0x02

	constructor: (@player) ->
		super @player, new Vector x: @player.speed, y: 0
