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
		p = new player.Player
			id: playerid

		@players.add p
		@world.add p.body

		return p

	getPlayer: (playerid) ->
		for player in @players.array
			return player if player.id == playerid

		return null

	tick: (time, dt) ->
		# Advance each player
		@players.forEach (player) ->
			player.tick time, dt
