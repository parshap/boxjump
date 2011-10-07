Model = require("../model").Model
physics = require("../physics")
player = require("./player")


exports.Game = class Game extends Model
	initialize: ->
		@_initializeWorld()

		@players = new player.PlayerList

	_initializeWorld: ->
		@world = new physics.World

	createPlayer: (playerid) ->
		player = new player.Player
			id: playerid
			game: @

		@players.add player

		return player

	tick: (dt) ->
		# Advance each player
		@players.forEach (player) ->
			player.tick dt
