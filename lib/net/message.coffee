msgpack = require "coffeepack"


exports.Message = class Message
	@unpack: (data) ->
		[id, args...] = msgpack.unpack data
		return new @ id, args

	constructor: (@id, @arguments = []) ->

	pack: ->
		msgpack.pack [@id, @arguments...]
