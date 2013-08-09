msgpack = require "coffeepack"
sio = require "socket.io"

Event = require("../event").Event
Model = require("../model").Model
List = require("../list").List
Message = require("./message").Message


exports.Server = class Server extends Event
	constructor: ->
		@clients = new ClientList()
		super()

	listen: (server) ->
		@io = sio.listen(server)
		@io.set "log level", 2
		@io.sockets.on "connection", (socket) =>
			client = new Client
				socket: socket

			@onConnect client

	# Called when a new connection is initiated, passed the new Client
	# object that was created for the new connection
	onConnect: (client) ->
		# Listen and handle events from the client
		client.bind "disconnect", => @onDisconnect client
		client.bind "message", (message) => @onMessage client, message

		# Add the client to our list of clients
		@clients.add client

		# Trigger a connect event, passing the connected client
		@trigger "connect", client

	# Called when a client connection is disconnected
	onDisconnect: (client) ->
		# Remove the client from our list of clients
		@clients.remove client

		# Trigger a disconnect event, passing the disconnected client
		@trigger "disconnect", client

	# Called when a client has sent us a message
	onMessage: (client, message) ->
		# Trigger a message event
		@trigger "message", client, message

	# Sends a message to all clients
	send: (message) ->
		@clients.send arguments...
		return this

	flush: ->
		@clients.flush arguments...
		return this

	# Filter clients
	filter: (filter) ->
		@clients.filter arguments...


class Client extends Model
	defaults:
		playerid: null
		lerp: 0
		rtt: 0

	buffer: null

	socket: null

	initialize: ->
		@buffer = []

		@socket.on "disconnect", =>
			@trigger "disconnect"

		@socket.on "message", (data) =>
			@trigger "message", Message.unpack data

	send: (message) ->
		@buffer.push message
		return this

	flush: ->
		@socket.send @packBuffer() if @buffer.length
		@buffer = []

		return this

	packBuffer: ->
		msgpack.pack (message.raw() for message in @buffer)


class ClientList extends List
	filter: (filter) ->
		if filter instanceof Client
			return new @constructor [filter]

		else if filter instanceof List
			# @TODO: Should this be a part of List#filter?
			return new @constructor filter.array

		else if filter instanceof Array
			return new @constructor filter

		else
			super arguments...

	# Sends the message to all clients in the list
	send: (message) ->
		@forEach (client) ->
			client.send message

		return this

	flush: ->
		@forEach (client) ->
			client.flush()

		return this
