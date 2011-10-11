View = require("./view").View
PlayerView = require("./player").PlayerView
WallView = require("./wall").WallView


exports.GameView = class GameView extends View
	id: "viewport"

	initialize: ->
		@playerViews = {}

		@game.players.bind "add", (player) =>
			@addPlayer player

		@game.players.bind "remove", (player) =>
			@removePlayer player

		# Create walls
		@game.walls.forEach (wall) =>
			view = new WallView wall: wall
			@el.appendChild view.el

	addPlayer: (player) ->
		view = new PlayerView player: player
		@playerViews[player.id] = view
		@el.appendChild view.el

	removePlayer: (player) ->
		if view = @playerViews[player.id]
			@el.removeChild view.el

	tick: (time, dt) ->
		for playerid, playerView of @playerViews
			playerView.tick time, dt
