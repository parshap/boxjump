Vector = require("../../physics/vector").Vector
Action = require("./action").Action


exports.Jump = class Jump extends Action
	DELAY: 120

	id: 0x03

	proxy: true

	can: -> not @player.body.airborne

	perform: (delay) ->
		[power] = @arguments
		console.log "jump", @player.velocity
		# @TODO Set velocity to absolute value instead of subtracting to
		# to avoid physics issues when jumping while body already has a
		# velocity
		@player.body.velocity.y -= @player.jump * power
		@player.body.trigger "effect"

	scheduleProxy: (time, performTime) ->
		early = performTime - time

		# We're late to play the animation, but not too late - play now!
		if 0 < early <= @DELAY
			@player.trigger "pre-jump"

		# We're early to play the animatio, play in a bit
		else if early > @DELAY
			setTimeout (=>
				@player.trigger "pre-jump"
			), (early - @DELAY)

		super arguments...

	proxy: (delay) ->
