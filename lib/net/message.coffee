msgpack = require "coffeepack"


exports.Message = class Message
	@unpack: (data) ->
		return @unraw msgpack.unpack data

	@unraw: ([id, args...]) ->
		return new @ id, args

	constructor: (@id, @arguments = []) ->

	pack: -> msgpack.pack @raw()

	raw: -> [@id, @arguments...]

exports.MessageList = class 
