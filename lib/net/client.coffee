msgpack = require "coffeepack"

Event = require("../event").Event
Message = require("./message").Message


exports.Client = class Client extends Event
	playerid: null

	constructor: ->
		@socket = null

		super()

	connect: ->
		@socket = io.connect()

		@socket.on "connect", => @trigger "connect"
		@socket.on "disconnect", => @trigger "disconnect"

		@socket.on "message", (data) =>
			for raw in msgpack.unpack data
				@trigger "message", Message.unraw raw

		return this

	send: (message) ->
		@socket.send message.pack()
