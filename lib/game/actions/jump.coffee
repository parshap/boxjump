Vector = require("../../physics/vector").Vector
Action = require("./action").Action


exports.Jump = class Jump extends Action
	id: 0x03

	DELAY: 120

	can: -> ! @player.body.airborne

	perform: (delay) ->
		[power] = @arguments

		jumpV = new Vector x: 0, y: -@player.jump * power

		@player.body.velocity.add jumpV

	scheduleProxy: (time, performTime) ->
		preTime = (performTime - @DELAY) - time

		console.log "scheduling jump proxy ahead", performTime - time

		if 0 <= preTime < time
			setTimeout (=>
				@player.trigger "pre-jump"
			), preTime

		super()

	proxy: (delay) ->

	predict: ->
		@perform 0
