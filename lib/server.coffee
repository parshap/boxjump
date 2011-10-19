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

		@_statesToSend = []
		@_lastStates = {}
		@_lastSentStates = {}
		@_lastSentStatesTime = null

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

		# Process current states, saving any to be sent to clients
		@_processStates time

		# Send any output to clients
		@_sendStates time
		@_sendActions time
		@net.flush()

	# The last time updates were sent
	_lastStatesSent: -Infinity

	# A snapshot of states at the last time updates were sent
	_lastStates: {}

	_processStates: (time) ->
		states = @_getStates(time)

		isFloatZero = (num) -> -0.00001 < num < 0.00001

		isSignChanged = (a, b) ->
			# No change if both are zero
			if isFloatZero(a)
				return not isFloatZero(b)

			else
				return true if isFloatZero(b)

				return (a > 0 and b <= 0) or (a < 0 and b >= 0)

		for state in states
			lastState = @_lastStates[state.id]
			lastSentState = @_lastSentStates[state.id]

			shouldSend =
				# If we've never sent this before
				not lastState or

				# If sign of the velocity has changed
				isSignChanged(state.velocity.x, lastState.velocity.x) or
				isSignChanged(state.velocity.y, lastState.velocity.y)

			if shouldSend
				@_statesToSend.push state

				# Send the previous state too
				if lastState and not lastState.sent
					@_statesToSend.push lastState

				@_lastSentStates[state.id] = state
				state.sent = true

		(@_lastStates[state.id] = state) for state in states

	# Sends the current states
	_sendStates: (time) ->
		# Send only once every @updateInterval
		return if (time - @_lastSentStatesTime) < @updateInterval

		send = (time, states) =>
			message = new Message 0x10, [time]

			for state in states
				message.arguments.push(
					state.id
					state.position.x
					state.position.y
				)

			@net.send message

		# Add current states along to any intermediate states we're sending
		for id, state of @_lastStates
			lastSentState = @_lastSentStates[state.id]

			if not _.isEqual state.position, lastSentState.position
				@_statesToSend.push state

		# Make sure the states are sorted by time
		@_statesToSend.sort (a, b) -> a.time - b.time

		states = []
		lastTime = null

		for state in @_statesToSend
			# Flush the buffered states when the time changes
			if state.time != lastTime
				# Send the buffered states of lastTime
				send lastTime, states if states.length

				# Clear the buffer
				states = []

			# Buffer this state to be sent
			states.push state

			lastTime = state.time

		# Flush the last set of states
		send lastTime, states if states.length

		@_statesToSend = []

		# Save the time we sent an update
		@_lastSentStatesTime = time

	# Generate a full copy of the current state
	_getStates: (time) ->
		states = []

		@game.players.forEach (player) ->
			states.push
				id: player.id
				time: time
				position:
					x: player.body.x
					y: player.body.y
				velocity:
					x: player.body._lastMovedV.x
					y: player.body._lastMovedV.y

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
				if action.id in _sentActions
					@_actionsToSend.push { action, time }

	# Broadcast any actions
	_sendActions: (time) ->
		for { action, time } in @_actionsToSend
			@net.send new Message 0x14, [
				time, action.id,  action.player.id, action.arguments...
			]

		@_actionsToSend = []

	_processActionRequests: (time) ->
		for { player, action, requestTime, client } in @_actionRequests
			delay = time - requestTime - client.get("lerp") - client.get("rtt")

			player.requestAction time, action, requestTime, delay

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
