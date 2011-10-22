net = require "./net/client"
Game = require("./game/game").Game
Event = require("./event").Event
Message = require("./net/message").Message
GameView = require("./view/game").GameView


exports.Application = class Application

	epoch: null

	lerp: 300

	rtt: 0

	_actionProxies: null

	_actionRequests: null

	_tickTime: null

	# -- Initialization

	constructor: ->
		@_initializeController()
		@_initializeNet()
		@_initializeReceiver()
		@_initializeSender()
		@_initializeGame()
		@_initializeView()

		@_actionProxies = []
		@_actionRequests = []

	_initializeGame: ->
		@game = new Game()
			lerp: @lerp

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

	_initializeController: ->
		@controller = new Controller()

		# Actions
		(=>
			# Queue actions on input to occur on the next tick
			queue = (action) =>
				@_actionRequests.push action

			# Movement
			# The player's current movement state is sent each time it
			# changes (buffered by 10ms)
			(=>
				timeoutid = null
				lastActionid = 0x00

				getActionid = =>
					if @controller.state.left and not @controller.state.right
						return 0x01
					if @controller.state.right and not @controller.state.left
						return 0x02
					return 0x00

				# Queues the movement action if there was a change in movement
				doAction = =>
					actionid = getActionid()
					action = new @player.actions[actionid] @player

					queue action if actionid != lastActionid

					lastActionid = actionid
					timeoutid = null

				# "Buffer" other state changes and send periodically
				change = ->
					timeoutid = setTimeout doAction, 10 if not timeoutid

				@controller.bind "right", change
				@controller.bind "left", change
			)()

			# Charge
			(=>
				DOUBLE_TAP_DELAY = 200

				actionids = left: 0x04, right: 0x05
				lastDown = left: null, right: null

				onDown = (direction) =>
					now = new Date().getTime()

					if now - lastDown[direction] <= DOUBLE_TAP_DELAY
						actionid = actionids[direction]
						action = new @player.actions[actionid] @player

						queue action

					lastDown[direction] = now

				for direction, actionid of actionids
					((direction) =>
						@controller.bind direction, (down) ->
							onDown direction if down
					)(direction)
			)()

			# Jump
			(=>
				jumping = false
				action = null

				jump = =>
					power = if @controller.state.jump then 1 else 0.75
					action.arguments = [power]

					queue action

					jumping = false

				@controller.bind "jump", (down) =>
					if down
						action = new @player.actions[0x03] @player

						if not jumping and action.predictCan()
							jumping = true
							@player.trigger "pre-jump"

							setTimeout jump, action.DELAY
			)()

			# Punch
			(=>
				@controller.bind "punch", (down) =>
					if down
						queue 0x10
			)()
		)()

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

			if dt > 0.1
				dt = 0.1
				console.log "Warning: Slow tick"

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

	_serverTime: (gameTime = null) ->
		gameTime or= @_gameTime()
		return gameTime + @lerp + @rtt

	# -- Game logic

	setPlayer: (player) ->
		@player = player
		@player.inputDelay = @rtt

	tick: (time, dt) ->
		# These tasks are handled within event callbacks on async io
		# components (such as net or a controller)
		# * Process any input from the server
		# * Process any input from input devices
		# * Send any output to the server

		@game.time = time

		# Process any input from the server
		@_processActionProxies time

		@_processActionRequests time

		# Update the game state
		@game.tick time, dt

		# Render the current game state
		@view.tick time, dt

	_processActionProxies: (time) ->
		for { player, action, performTime } in @_actionProxies
			if action.proxyOwnPlayer or player != @player
				player.proxyAction time, action, performTime

		@_actionProxies = []

	_processActionRequests: (time) ->
		# First a test occurs to see if the player can currently perform
		# the action. If this test passes locally (client-side), then
		# the client both sends a request to perform the action to the
		# server and predicts the outcome of that action.
		
		for action in @_actionRequests
			# Predict if the player can perform this action
			if action.predictCan()
				# Request the server to perform this action
				@sender[0x13] time, action

				# Predict the result of performing this action
				@player.predictAction action

		@_actionRequests = []


class MessageReceiver
	constructor: (@app) ->

	# Time Sync
	0x00: (message) ->
		if message.arguments.length == 2
			# @TODO: Some statistical analysis
			# http://codewhore.com/howto1.html
			[sent, received] = message.arguments
			now = new Date().getTime()
			rtt = now - sent
			diff = @app._gameTime(now) - (received - @app.lerp)

			console.log "Sync RTT", rtt, "Sync Diff", diff

			# Discard if RTT > 200ms
			if rtt > 200
				console.log "Warning: Discarding time sync with rtt", rtt
				return

			if Math.abs(diff) > 100
				console.log "Warning: Latency changed - synchronizing time", diff
				@app.epoch -= (received - @app.lerp) - @app._gameTime(now)
				@app.rtt = rtt

				@player?.inputDelay = rtt

				# @TODO: Resync the player when changing epoch

				# Tell the server about changes
				@app.sender[0x02]()

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

		# Iterate through given player arguments
		while (args.length - pos) >= 3
			playerid = args[pos++]

			# Deconstruct arguments into state object
			state =
				time: time
				x: args[pos++]
				y: args[pos++]

			# Get the player or create one
			player = @app.game.getPlayer(playerid) or
				@app.game.createPlayer(playerid)

			player.body.states.push state if player != @app.player

	# Player Leave
	0x12: (message) ->
		[playerid] = message.arguments

		if player = @app.game.getPlayer playerid
			@app.game.removePlayer player

	# Action
	0x14: (message) ->
		[performTime, actionid, playerid, args...] = message.arguments

		if player = @app.game.getPlayer playerid
			action = new player.actions[actionid] player, args...

			@app._actionProxies.push { player, action, performTime }


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

	# Client Info
	0x02: ->
		@app.net.send new Message 0x02, [@app.lerp, @app.rtt]

	# Chat Message
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

	# Player Action Request
	0x13: (requestTime, action) ->
		@app.net.send new Message 0x13, [requestTime, action.id, action.arguments...]


class Controller extends Event
	KEYS:
		87: "up" # w
		65: "left" # a
		83: "down" # s
		68: "right" # d

		32: "jump" # space

		37: "punch" # left arrow
		38: "punch" # up arrow
		39: "punch" # right arrow
		40: "punch" # down arrow

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
