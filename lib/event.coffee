# Event
#
# Event class derived from Jeremy Ashkenas' Backbone.js and Jerome
# Etienne's microevents.js.
# https://github.com/documentcloud/backbone
# https://raw.github.com/jeromeetienne/microevent.js
exports.Event = class Event
	constructor: ->
		@_callbacks = {}

	bind: (name, callback) ->
		@_callbacks[name] or= []
		@_callbacks[name].push(callback)

		return this

	unbind: (name, callback) ->
		# Reset all events
		if not name
			@_callbacks = {}

		# Reset a single event
		else if not callback
			@_callbacks[name] = []

		# Remove just the single callback
		else if @_callbacks[name]
			@_callbacks[name] = (cb for cb in @_callbacks[name] when cb != callback)

		return this

	trigger: (name) ->
		return this if not @_callbacks[name]

		args = Array.prototype.slice.call(arguments, 1)
		callback.apply(null, args) for callback in @_callbacks[name]

		return this
