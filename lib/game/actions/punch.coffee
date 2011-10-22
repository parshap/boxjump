Vector = require("../../physics/vector").Vector
Action = require("./action").Action
Move = require("./move").Move
MoveNone = require("./move").MoveNone


exports.Punch = class Punch extends Action
	id: 0x10

	proxy: true

	proxyOwnPlayer: true

	can: -> not @player.body.airborne and
		not @player.onCooldown() and
		not @player.onCooldown("punch")

	# Schedule to perform the action requested at the given time
	# `delay` is how late we are to schedule the action
	schedule: (time, requestTime, delay) ->
		performTime = requestTime + 400
		performTime = time if performTime < time

		cdTime = performTime + 800
		@player.setCooldown "move", performTime

		@stopMove()

		return performTime

	scheduleProxy: (time, performTime) ->
		cdTime = performTime + 800 - @player.game.lerp - @player.inputDelay
		@player.setCooldown "move", cdTime, true

		return performTime

	# Performs the action
	# `delay` is how late we are to perform the action
	perform: (delay) ->

	# Performs a proxied action
	# `delay` is how late we are to perform the action
	proxy: (delay) ->

	# Predicts the outcome of the action being requested
	predict: ->
		@player.setCooldown("move", @player.game.time + 800)
		@stopMove()

	stopMove: (delay=0) ->
		@player.performAction new MoveNone @player
