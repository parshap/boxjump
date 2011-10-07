Model = require("../model").Model
physics = require("../physics")
player = require("./player")
wall = require("./wall")
map = require("./map")


exports.Game = class Game extends Model
	initialize: ->
		@players = new player.PlayerList
		@walls = new wall.WallList

		@_initializeWorld()

	_initializeWorld: ->
		@world = new physics.World
		@world.gravityF = x: 0, y: 20

		# Load the map
		map().forEach (wall) =>
			@walls.add wall
			@world.add wall.body

	createPlayer: (playerid) ->
		player = new player.Player
			id: playerid

		@players.add player
		@world.add player.body

		return player

	tick: (dt) ->
		# Advance each player
		@players.forEach (player) ->
			player.tick dt
