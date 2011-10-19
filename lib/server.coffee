_ = require "underscore"
net = require "./net/server"
Game = require("./game/game").Game
Message = require("./net/message").Message


exports.Application = class Application

	epoch: null

	updateInterval: 250

	tickTime: null

	_actionRequests: null

	_actionsToSend: null

	# -- Initialization

	constructor: ->
		@_playerCount = 0
		@_actionRequests = []

		@_initializeNet()
		@_initializeReceiver()
		@_initializeGame()
		@_initializeSendActions()

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
			@tickTime = tickTime = now
			@gameTime = gameTime = @_gameTime tickTime

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
		@_processActionRequests time

		# Update the game state
		@game.tick time, dt

		# Send any output to clients
		@_sendStates time
		@_sendActions time
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

	_sentActions = [
		0x03 # Jump
		0x10 # Punch
	]

	_actionsToSend: null

	_initializeSendActions: ->
		@_actionsToSend = []

		@game.players.bind "add", (player) =>
			# @TODO: listener leak?
			player.bind "schedule-action", (action, time) =>
				if actionid in _sentActions
					@_actionsToSend.push { action, time }

	# Broadcast any actions
	_sendActions: (time) ->
		for { action, time } in @_actionsToSend
			@net.send new Message 0x14, [
				time, actionid,  action.player.id, action.arguments...
			]

		@_actionsToSend = []

	_processActionRequests: (time) ->
		for { player, action, requestTime, client } in @_actionRequests
			delay = time - requestTime - client.lerp - client.rtt

			player.performAction action, requestTime, delay

		@_actionRequests = []

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
			[requestTime, actionid, args...] = message.arguments

			action = new player.actions[actionid] player, args...

			@app._actionRequests.push
				player: player
				action: action
				requestTime: requestTime
				client: client
