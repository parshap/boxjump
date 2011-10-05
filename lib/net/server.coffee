msgpack = require "coffeepack"
sio = require "socket.io"

Event = require("../event").Event
List = requjire("../list").List

Message = require("./message").Message


exports.Server = class Server extends util.Event
	constructor: (server) ->
		@clients = new ClientList()
		@io = sio.listen server

		@io.sockets.on "connection", (socket) =>
			client = new Client
				socket: socket

			@onConnect client

		super()

	# Called when a new connection is initiated, passed the new Client
	# object that was created for the new connection
	onConnection: (client) ->
		# Listen and handle events from the client
		client.on "disconnect", => @onDisconnect client
		client.on "message", (message) => @onMessage client, message

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
		@clients.send message


class Client extends Model
	initialize: ->
		@socket.on "disconnect", =>
			@trigger "disconnect"

		@socket.on "message", (data) =>
			@trigger "message", Message.unpack data

	send: (message) ->
		@socket.send message.pack()


class ClientList extends List
	# Sends the message to all clients in the list
	send: (message) ->
		@forEach (client) ->
			client.send message
