View = require("./view").View
PlayerView = require("./player").PlayerView


exports.GameView = class GameView extends View
	id: "viewport"

	initialize: ->
		@playerViews = {}
		@addedPlayers = []

		@game.players.bind "add", (player) =>
			@addedPlayers.push player

	addPlayer: (player) ->
		view = new PlayerView player: player
		@playerViews[player.id] = view
		@el.appendChild view.el

	tick: (dt) ->
		# Add any new players
		@addedPlayers.forEach (player) =>
			@addPlayer player

		# Clear the new players array
		@addedPlayers.length = 0

		for playerid, playerView of @playerViews
			playerView.tick dt
