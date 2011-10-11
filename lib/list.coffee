Event = require("./event").Event

exports.List = class List extends Event
	constructor: (@array = []) ->
		super()

	add: (thing, options = {}) ->
		@array.push thing

		@trigger "add", arguments... if not options.silent

		return this

	remove: (thing, options = {}) ->
		@array.splice @array.indexOf(thing), 1

		@trigger "remove", arguments... if not options.silent

		return this

	forEach: ->
		@array.forEach(arguments...)

		return this

	# Proxy array "iteration methods"
	[
		"filter"
		"forEach"
		"every"
		"map"
		"some"
		"reduce"
		"reduceRight"
	].forEach (name) =>
		@prototype[name] = ->
			new @constructor @array[name] arguments...
