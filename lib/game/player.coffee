physics = require "../physics"
Model = require("../model").Model
List = require("../list").List


exports.Player = class Player extends Model
	speed: 10

	defaults:
		x: 0
		y: 0
		width: 1.5
		height: 2

	initialize: ->
		# Create a body for this player
		@body = new physics.Rect(
			@get("x")
			@get("y")
			@get("width")
			@get("height")
		)

		# @TODO: The body probably needs a back reference to this player

		# Create an impulse effect that will be used for movement
		@moveI = @body.impulse x: 0, y: 0

	input: (state) ->
		{right, left} = state

		if (right and left) or (not right and not left)
			@moveI.x = 0
		else
			@moveI.x = -@speed if left
			@moveI.x = @speed if right

	predictInput: (state) ->
		# @TODO
		@input state

	tick: (time, dt) ->
		@body.tick time, dt


exports.PlayerList = class PlayerList extends List
