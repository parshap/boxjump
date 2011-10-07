net = require "./net/client"
Game = require("./game/game").Game
Event = require("./event").Event
Message = require("./net/message").Message
GameView = require("./view/game").GameView


exports.Application = class Application
	_lastTick: null

	# -- Initialization

	constructor: ->
		@_initializeController()
		@_initializeNet()
		@_initializeReceiver()
		@_initializeSender()
		@_initializeGame()
		@_initializeView()

	_initializeGame: ->
		@game = new Game()

	_initializeNet: ->
		@net = new net.Client()

		@net.bind "connect", =>
			@_sync()
			@sender[0x01]()

	_initializeReceiver: ->
		@receiver = new MessageReceiver @

		@net.bind "message", (message) =>
			console.log "Message from server", message.id, message.arguments
			if @receiver[message.id]?
				@receiver[message.id] message
			else
				# @TODO: Unknown messsage received
				console.log "Unknown message", message

	_initializeSender: ->
		@sender = new MessageSender @

		# Send player input changes

		# @TODO: Should this setup be here? Where else will we send
		# messages from?
		(=>
			timeoutid = null

			# Send the current input state to the server
			send = =>
				@sender[0x11] @controller.state
				@player.predictInput @controller.state
				timeoutid = null

			# "Buffer" other state changes and send periodically
			change = =>
				timeoutid = setTimeout send, 10 if not timeoutid

			@controller.bind "up", change
			@controller.bind "right", change
			@controller.bind "down", change
			@controller.bind "left", change
		)()

	_initializeController: ->
		@controller = new Controller()

		# @TODO: Predict input state changes locally

	_initializeView: ->
		@view = new GameView
			game: @game
		document.getElementById("game").appendChild @view.el

	# Connect to a server
	connect: ->
		@net.connect()

		return this

	# Start the game loop
	start: ->
		lastTick = new Date().getTime()

		setInterval (=>
			now = new Date().getTime()
			dt = (now - lastTick) / 1000
			@tick dt
			lastTick = now
		), 1000/60

		return this

	_sync: ->
		@sender[0x00]()

		setTimeout (=>
			@_sync()
		), 5000

	# -- Game logic

	createPlayer: (playerid) ->
		player = @game.createPlayer playerid

	setPlayer: (player) ->
		@player = player

	tick: (dt) ->
		# These tasks are handled within event callbacks on async io
		# components (such as net or a controller)
		# * Process any input from the server
		# * Process any input from input devices
		# * Send any output to the server

		# Interpolate/extrapolate any game state from server updates
		@_interpolate dt

		# Update the game state
		@game.tick dt

		# Render the current game state
		@view.tick dt

		@_lastTick = new Date().getTime()

	_lastState: {}
	_curState: {}

	_interpolate: (dt) ->
		time = @game.time + dt

		for playerid, state of @_lastState
			if state.time > time
				console.log "Warning: last known state ahead of simulation time"
				continue

			player = @game.getPlayer state.playerid

			pastState = state if state.time < time

			if curState = @_curState[playerid]
				if curState.time <= time
					console.log "new state too old"
					pastState = curState
					curState = null

			if pastState and curState
				console.log "Interpolate", pastState, curState, time

			# player.interpolate pastState, curState, time


class MessageReceiver
	constructor: (@app) ->

	# Time Sync
	0x00: (message) ->
		if message.arguments.length == 2
			[sent, received] = message.arguments
			now = new Date().getTime()

			# Discard if RTT > 200ms
			rtt = now - sent
			if rtt > 200
				console.log "Discarding time sync with rtt", rtt
				return

			elapsed = (now - @app._lastTick) / 1000
			oldTime = @app.game.time
			newTime = (received - elapsed) - 0.1
			diff = newTime - @app.game.time

			if diff > 0.5
				@app.game.time = newTime
				console.log "Synchronized time", oldTime, newTime, diff

	# Join Response
	0x02: (message) ->
		[playerid] = message.arguments

		@app.setPlayer @app.createPlayer playerid

	# Chat Message
	0x0A: (message) ->
		[playerid, text] = message.arguments
		console.log "Message", playerid, text
		# @TODO: Display message text

	# Game State
	0x10: (message) ->
		# We got a game state update

		# Move the previous ones ...
		for playerid, state of @app._curState
			@app._lastState[playerid] = state

		# Add the new ones
		@app._curState = {}

		[time, args...] = message.arguments
		pos = 0

		console.log "Got state", time, @app.game.time

		# Iterate through given player arguments
		while (args.length - pos) >= 5
			# Deconstruct arguments into state object
			state =
				time: time
				playerid: args[pos++]
				position:
					x: args[pos++]
					y: args[pos++]
				velocity:
					x: args[pos++]
					y: args[pos++]

			# Add this player state
			@app._curState[state.playerid] = state

		# @TODO: Do something with states


class MessageSender
	constructor: (@app) ->

	# Time Sync
	0x00: ->
		now = new Date().getTime()
		@app.net.send new Message 0x00, [now]
		console.log "Sending sync", now

	# Join Request
	0x01: ->
		@app.net.send new Message 0x01

	0x0A: (text) ->
		# @TODO: Get real playerid
		playerid = 0
		@app.net.send new Message 0x0A, [playerid, text]

	# Player Input
	0x11: ({up, right, down, left}) ->
		state = 0
		state |= (1 << 3) if up
		state |= (1 << 2) if right
		state |= (1 << 1) if down
		state |= (1 << 0) if left

		@app.net.send new Message 0x11, [state]


class Controller extends Event
	KEYS:
		87: "up" # w
		65: "left" # a
		83: "down" # s
		68: "right" # d

		32: "jump" # space

	constructor: ->
		@state = {}
		@state[event] = false for key, event of @KEYS

		document.addEventListener "keydown", (e) => @handle e, true
		document.addEventListener "keyup", (e) => @handle e, false

		super()

	handle: (e, down) ->
		key = e.key || e.keyCode || e.which
		event = @KEYS[key]

		# We don't care about this event
		return if not event

		# Update the state and trigger an event if it changed
		changed = !!@state[event] != down
		@state[event] = down
		@trigger event, down if changed
