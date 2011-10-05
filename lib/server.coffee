Event = require("./event").Event


exports.Application = class Application

	# -- Initialization

	constructor: ->
		@_initializeNet()
		@_initializeReceiver()
		@_initializeSender()
		@_initializeGame()

	_initializeGame: ->
		@game = new Game()

	_initializeNet: ->
		@net = new net.Client().connect()

	_initializeReceiver: ->
		@receiver = new MessageReceiver @

		@net.bind "message", (client, message) =>
			if message.id in @receiver
				@receiver[message.id] client, message
			else
				# @TODO: Unknown messsage received
				console.log "Unknown message", client, message

	_initializeSender: ->
		@sender = new MessageSender @

	# -- Game loop

	tick: (dt) ->
		# Process input from clients
		# @TODO

		# Update the game state
		@game.tick dt

		# Send any output to clients
		# @TODO


class MessageReceiver
	construct: (@app) ->

	# Join Request
	0x01: (client, message) ->
		# Generate some playerid
		playerid = parseInt(Math.random() * 128)

		# Send a Join Response to the requesting client
		@app.net
			.filter client
			.send 0x02, playerid

	# Player Input
	0x11: (client, message) ->
		# @TODO
