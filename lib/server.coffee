net = require "./net/server"
game = require("./game")
Event = require("./event").Event
Message = require("./net/message").Message


exports.Application = class Application

	# -- Initialization

	constructor: ->
		@_initializeNet()
		@_initializeReceiver()
		@_initializeGame()

	_initializeGame: ->
		# @game = new Game()

	_initializeNet: ->
		@net = new net.Server()

	_initializeReceiver: ->
		@receiver = new MessageReceiver @

		@net.bind "message", (client, message) =>
			if @receiver[message.id]?
				@receiver[message.id] client, message
			else
				# @TODO: Unknown messsage received
				console.log "Unknown message", client, message

	# Starts listening to a server
	listen: (server) ->
		@net.listen server

	# -- Game loop

	tick: (dt) ->
		# Process input from clients
		# @TODO

		# Update the game state
		@game.tick dt

		# Send any output to clients
		# @TODO


class MessageReceiver
	constructor: (@app) ->

	# Join Request
	0x01: (client, message) ->
		# Generate some playerid
		playerid = parseInt(Math.random() * 128)

		# Send a Join Response to the requesting client
		@app.net
			.filter(client)
			.send new Message 0x02, [playerid]

	# Chat Message
	0x0A: (client, message) ->
		# @TODO: Validate the message's playerid
		# @TODO: rate limit?
		@app.net.send message

	# Player Input
	0x11: (client, message) ->
		# @TODO
