msgpack = require "coffeepack"

Event = require("../event").Event
Message = require("./message").Message


exports.Client = class Client extends Event
	constructor: ->
		@socket = null

		super()

	connect: ->
		@socket = io.connect()

		@socket.on "connect", => @trigger "connect"
		@socket.on "disconnect", => @trigger "disconnect"

		@socket.on "message", (data) =>
			@trigger "message", Message.unpack data

		return this

	send: (message) ->
		@socket.send message.pack()
