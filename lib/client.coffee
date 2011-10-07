net = require "./net/client"
game = require("./game")
Event = require("./event").Event
Message = require("./net/message").Message
GameView = require("./view/game").GameView


exports.Application = class Application

	# -- Initialization

	constructor: ->
		@_initializeController()
		@_initializeNet()
		@_initializeReceiver()
		@_initializeSender()
		@_initializeGame()
		@_initializeView()

	_initializeGame: ->
		@game = new game.Game()

	_initializeNet: ->
		@net = new net.Client()

		@net.bind "connect", =>
			@sender[0x01]()

	_initializeReceiver: ->
		@receiver = new MessageReceiver @

		@net.bind "message", (message) =>
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

	# -- Game logic

	createPlayer: (playerid) ->
		@player = @game.createPlayer playerid

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
		@view.tick dt

	_interpolate: ->
		# @TODO


class MessageReceiver
	constructor: (@app) ->

	# Join Response
	0x02: (message) ->
		[playerid] = message.arguments

		@app.createPlayer playerid

	# Chat Message
	0x0A: (message) ->
		[playerid, text] = message.arguments
		console.log "Message", playerid, text
		# @TODO: Display message text

	# Game State
	0x10: (message) ->
		[time, args...] = message.arguments
		states = []
		pos = 0

		# Iterate through given player arguments
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


class MessageSender
	constructor: (@app) ->

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
