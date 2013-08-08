Vector = require("../../physics/vector").Vector
Rect = require("../../physics/rect").Rect
Action = require("./action").Action
Move = require("./move").Move
MoveNone = require("./move").MoveNone


exports.Punch = class Punch extends Action
	id: 0x10

	proxy: true

	proxyOwnPlayer: true

	hitPlayers: null

	initialize: ->
		@hitPlayers = []

	can: -> not @player.body.airborne and
		not @player.onCooldown() and
		not @player.onCooldown("punch")

	# Schedule to perform the action requested at the given time
	# `delay` is how late we are to schedule the action
	schedule: (time, requestTime, delay) ->
		performTime = requestTime + 400
		performTime = time if performTime < time

		cdTime = performTime + 800
		@player.setCooldown "move", cdTime

		@stopMove delay

		return performTime

	scheduleProxy: (time, performTime) ->
		cdTime = performTime + 800 - @player.game.lerp - @player.inputDelay
		@player.setCooldown "move", cdTime, true

		return performTime

	# Performs the action
	# `delay` is how late we are to perform the action
	perform: (delay) ->
		width = 2.9
		height = 1.4
		x = @player.body.position.x + (width / 2)
		y = @player.body.position.y + 0.1
		hitBody = new Rect x, y, width, height

		# Collide with players only
		hitBody.on "collide", (body) =>
			@hitPlayers.push body if body.player? \
				and body.player != @player \
				and body.player not in @hitPlayers

		onTick = ->
			hitBody.collide @game.players.getBodies()

		stopTime = @player.game.time + 50

		@player.bind "tick", onTick

		@player.bindNextTickAfter stopTime, =>
			@player.unbind "tick", onTick

			@resolveHits()

	# Performs a proxied action
	# `delay` is how late we are to perform the action
	proxy: (delay) ->

	# Predicts the outcome of the action being requested
	predict: ->
		@player.setCooldown("move", @player.game.time + 800)
		@stopMove()

	resolveHits: ->
		console.log "punch hit players", @hitPlayers.length
		for player in @hitPlayers
			player.set health: player.get("health") - 50

	stopMove: (delay=0) ->
		@player.performAction new MoveNone(@player), delay
