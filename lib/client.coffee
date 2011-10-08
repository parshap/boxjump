net = require "./net/client"
Game = require("./game/game").Game
Event = require("./event").Event
Message = require("./net/message").Message
GameView = require("./view/game").GameView


exports.Application = class Application

	epoch: null

	_tickTime: null

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
		# @TODO: tickTime can be local
		@_tickTime = new Date().getTime()

		setInterval (=>
			now = new Date().getTime()
			dt = (now - @_tickTime) / 1000
			@_tickTime = now
			gameTime = @_gameTime @_tickTime
			@tick gameTime, dt
		), 1000/60

		return this

	_sync: ->
		@sender[0x00]()

		setTimeout (=>
			@_sync()
		), 5000

	# Returns the game time at the given tick time (defaults to now)
	_gameTime: (now = null) ->
		now or= new Date().getTime()
		return now - @epoch

	# -- Game logic

	setPlayer: (player) ->
		@player = player

	tick: (time, dt) ->
		# These tasks are handled within event callbacks on async io
		# components (such as net or a controller)
		# * Process any input from the server
		# * Process any input from input devices
		# * Send any output to the server

		# Update the game state
		@game.tick time, dt

		# Render the current game state
		@view.tick time, dt


class MessageReceiver
	constructor: (@app) ->

	# Time Sync
	0x00: (message) ->
		if message.arguments.length == 2
			[sent, received] = message.arguments
			now = new Date().getTime()

			# Discard if RTT > 200ms
			if (rtt = now - sent) > 200
				console.log "Warning: Discarding time sync with rtt", rtt
				return

			if (diff = Math.abs(@app._gameTime(now) - received)) > 50
				console.log "Warning: Latency changed - synchronizing time", diff
				@app.epoch -= received - now

	# Join Response
	0x02: (message) ->
		[playerid] = message.arguments

		@app.setPlayer @app.game.createPlayer playerid

	# Chat Message
	0x0A: (message) ->
		[playerid, text] = message.arguments
		console.log "Message", playerid, text
		# @TODO: Display message text

	# Game State
	0x10: (message) ->
		[time, args...] = message.arguments
		pos = 0

		console.log "Got state", time, @app._gameTime()

		# Iterate through given player arguments
		while (args.length - pos) >= 5
			playerid = args[pos++]

			# Deconstruct arguments into state object
			state =
				time: time
				position:
					x: args[pos++]
					y: args[pos++]
				velocity:
					x: args[pos++]
					y: args[pos++]

			# Get the player or create one
			player = @app.game.getPlayer(playerid) or
				@app.game.createPlayer(playerid)

			player.body.states.push state


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
