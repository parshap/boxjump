_ = require "underscore"
net = require "./net/server"
Game = require("./game/game").Game
Message = require("./net/message").Message


exports.Application = class Application

	epoch: null

	actions: null

	updateInterval: 250

	# -- Initialization

	constructor: ->
		@_playerCount = 0
		@actions = []

		@_initializeNet()
		@_initializeReceiver()
		@_initializeGame()

	_initializeGame: ->
		@game = new Game()

	_initializeNet: ->
		@net = new net.Server()

		# When a client disconnects, remove them from the gamea nd send a
		# PlayerLeave message
		@net.bind "disconnect", (client) =>
			if player = @game.getPlayer client.get("playerid")
				@game.removePlayer player

				@net.send new Message 0x12, [player.id]

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


		# Sort queued actions by time (ascending)
		@actions.sort (a, b) -> a.time - b.time

		while @actions.length and @actions[0].time <= time
			action = @actions.shift()
			delay = time - action.time - action.lerp - action.rtt

			console.log "Action delay", delay

			if Math.abs(delay) > 200
				console.log "Warning: Dropping action #{action.actionid} late", delay
				continue

			if player = @game.getPlayer action.playerid
				player.perform action.actionid, action.time, delay, action.args

		# Update the game state
		@game.tick time, dt

		# Send any output to clients
		@_sendStates time
		@net.flush()

	# The last time updates were sent
	_lastStatesSent: -Infinity

	# A snapshot of states at the last time updates were sent
	_lastStates: {}

	# Sends the current states
	_sendStates: (time) ->
		# Send only once every @updateInterval
		return if (time - @_lastStatesSent) < @updateInterval

		send = (time, states) =>
			message = new Message 0x10, [time]

			for state in states
				state.sent = true

				message.arguments.push(
					state.id
					state.position.x
					state.position.y
				)

			@net.send message

		# Current states
		states = @_getStates()

		# States to be sent
		sendStates = []

		# We only need to send a subset of the current states
		for state in states
			lastState = @_lastStates[state.id]

			# If the position has changed, we need to send this state
			if not  _.isEqual state.position, lastState?.position
				# We will ensure the last state is known also
				# @TODO: We should send the time right before the change
				# occured.
				if lastState and not lastState.sent
					send @_lastStatesSent, [lastState]

				sendStates.push state

		# Send the states
		send time, sendStates if sendStates.length

		# Save the current states
		@_lastStates = {}
		@_lastStates[state.id] = state for state in states

		# Save the time we sent an update
		@_lastStatesSent = time

	# Generate a full copy of the current state
	_getStates: ->
		states = []

		@game.players.forEach (player) ->
			states.push
				id: player.id
				position:
					x: player.body.x
					y: player.body.y

		return states

class MessageReceiver
	constructor: (@app) ->

	# Time Sync
	0x00: (client, message) ->
		message.arguments.push @app._gameTime()

		@app.net
			.filter(client)
			.send(message)
			.flush()

	# Join Request
	0x01: (client, message) ->
		# Create a player for the client
		player = @app.createPlayer()
		client.set playerid: player.id

		# Send a Join Response to the requesting client
		@app.net
			.filter(client)
			.send(new Message 0x02, [player.id])
			.flush()

	# Client Info
	0x02: (client, message) ->
		[lerp, rtt] = message.arguments

		client.set { lerp, rtt }

	# Chat Message
	0x0A: (client, message) ->
		# @TODO: Validate the message's playerid
		# @TODO: rate limit?
		@app.net.send message

	# Player Input
	0x11: (client, message) ->
		if player = @app.game.getPlayer client.get("playerid")
			[state] = message.arguments

			up = !! (state & (1 << 3))
			right = !! (state & (1 << 2))
			down = !! (state & (1 << 1))
			left = !! (state & (1 << 0))

			player.input { up, right, down, left }

	# Action Request
	0x13: (client, message) ->
		if player = @app.game.getPlayer client.get("playerid")
			[time, actionid, args...] = message.arguments

			@app.actions.push
				playerid: client.get("playerid")
				actionid: actionid
				time: time
				args: args
				lerp: client.get("lerp")
				rtt: client.get("rtt")
