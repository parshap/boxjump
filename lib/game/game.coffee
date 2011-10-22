Model = require("../model").Model
physics = require("../physics")
Player = require("./player").Player
PlayerList = require("./player").PlayerList
wall = require("./wall")
map = require("./map")


exports.Game = class Game extends Model
	# The current game time
	# An outside source (that also drives the game loop) is responsible
	# for updating this at the *beginning* of every tick.
	time: null

	lerp: null

	initialize: ->
		@players = new PlayerList
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
		player = new Player
			id: playerid
			game: @

		@players.add player
		@world.add player.body

		return player

	getPlayer: (playerid) ->
		for player in @players.array
			return player if player.id == playerid

		return null

	removePlayer: (player) ->
		@players.remove player
		@world.remove player.body

	tick: (time, dt) ->
		# Advance each player
		@players.forEach (player) ->
			player.tick time, dt
