Model = require("../model").Model

exports.Application = class Application
	initialize: ->
		@net = @_initializeNet()
		@controller = @_initializeController()
		@game = @_initializeGame()

	tick: (dt) ->
		# These tasks are handled within event callbacks on async io
		# components (such as net or a controller)
		# * Process any input from the server
		# * Process any input from input devices
		# * Send any output to the server

		# Interpolate/extrapolate any game state from server updates
		@_interpolate()

		# Update the game state
		@game.tick dt

		# Render the current game state

	inputHandlers:
		input: (playerid, state) ->
			# Get a player model from the given player id
			#player = 

			player.input(state)

		update: (states) ->

	_initializeGame: ->
		game = new Game()

		return game

	_initializeNet: ->
		net = new net.Client()

		# @TODO: Setup RPC to @inputHandlers

		return net

	_initializeController: ->
		controller = new Controller()

		# @TODO: Send input state changes to server
		# @TODO: Predict input state changes locally

		return controller

	_interpolate: ->
		# @TODO


exports.MessageReceiver = class MessageReceiver
	constructor: ->

	# Join Response
	0x02: (playerid) ->
		# @TODO: Do something with playerid

	# Game State
	0x10: (time, args...) ->
		states = []

		# Iterate through given player arguments
		pos = 0
		while (args.length - pos) >= 5
			# Deconstruct arguments into state object
			state =
				time: time
				playerid: args[pos]
				position:
					x: args[pos + 1]
					y: args[pos + 2]
				velocity:
					x: args[pos + 3]
					y: args[pos + 4]

			# Add this player state to list of states
			states.push state

			# Advance to the next player parameters
			pos += 5

		# @TODO: Do something with states


exports.Controller = class Controller
