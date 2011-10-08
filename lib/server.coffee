_ = require "underscore"
net = require "./net/server"
Game = require("./game/game").Game
Event = require("./event").Event
Message = require("./net/message").Message


exports.Application = class Application

	epoch: null

	# -- Initialization

	constructor: ->
		@_playerCount = 0

		@_initializeNet()
		@_initializeReceiver()
		@_initializeGame()

	_initializeGame: ->
		@game = new Game()

	_initializeNet: ->
		@net = new net.Server()

	_initializeReceiver: ->
		@receiver = new MessageReceiver @

		@net.bind "message", (client, message) =>
			console.log "Received message", message.id, message.arguments
			if @receiver[message.id]?
				@receiver[message.id] client, message
			else
				# @TODO: Unknown messsage received
				console.log "Unknown message", client, message

	# Starts listening to a server
	listen: (server) ->
		@net.listen server

		return this

	# Start the game loop
	start: ->
		# Start the game time at 0
		tickTime = new Date().getTime()
		@epoch = tickTime

		setInterval (=>
			now = new Date().getTime()
			dt = (now - tickTime) / 1000
			tickTime = now
			gameTime = @_gameTime tickTime

			console.log "Game time", gameTime, "at", tickTime
			@tick gameTime, dt
		), 1000/120

		return this

	# Returns the game time at the given tick time (defaults to now)
	_gameTime: (now = null) ->
		now or= new Date().getTime()
		return now - @epoch

	# -- Game logic

	createPlayer: ->
		player = @game.createPlayer @_playerCount
		@_playerCount += 1

		return player

	tick: (time, dt) ->
		# Process input from clients
		# This is done as the input is received by the MessageReceiver

		# Update the game state
		@game.tick time, dt

		@_sendState time
		# Send any output to clients
		# @TODO

	_lastSentState: -Infinity
	_lastState: {}

	_sendState: (time) ->
		# Send every 50ms
		return if (time - @_lastSentState) < 0.050

		state = @_getState() # Current state
		message = new Message 0x10, [time]

		for playerid, pstate of state
			# Compare the current state to the previous state and if they are
			# different, add the player state to the message to send
			if not _.isEqual pstate, @_lastState[playerid]
				message.arguments.push(
					pstate.id
					pstate.x
					pstate.y
					pstate.vx
					pstate.vy
				)

		# Send the message if there is any data
		@net.send message if message.arguments.length > 1

		@_lastState = state
		@_lastSentState = time

	# Generate a full copy of the current state
	_getState: ->
		state = {}

		for player in @game.players.array
			state[player.id] =
				id: player.id
				x: player.body.x
				y: player.body.y
				vx: player.body.velocity.x
				vy: player.body.velocity.y

		return state

class MessageReceiver
	constructor: (@app) ->

	# Time Sync
	0x00: (client, message) ->
		message.arguments.push @app._gameTime()

		@app.net
			.filter(client)
			.send message

	# Join Request
	0x01: (client, message) ->
		# Create a player for the client
		player = @app.createPlayer()
		client.playerid = player.id

		# Send a Join Response to the requesting client
		@app.net
			.filter(client)
			.send new Message 0x02, [player.id]

	# Chat Message
	0x0A: (client, message) ->
		# @TODO: Validate the message's playerid
		# @TODO: rate limit?
		@app.net.send message

	# Player Input
	0x11: (client, message) ->
		if player = @app.game.getPlayer client.playerid
			[state] = message.arguments

			up = !! (state & (1 << 3))
			right = !! (state & (1 << 2))
			down = !! (state & (1 << 1))
			left = !! (state & (1 << 0))

			player.input { up, right, down, left }
