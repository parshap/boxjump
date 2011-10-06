_ = require "underscore"
Event = require("./event").Event


exports.Model = class Model extends Event
	defaults: {}

	constructor: (options = {}) ->
		super()

		@attributes = _.clone(@defaults)
		@_changing = false

		for attr, val of options
			@[attr] = val

		@initialize()

	initialize: ->

	get: (attr) ->
		return @attributes[attr]

	set: (attrs, options = {}) ->
		changed = false

		for own attr, val of attrs
			if not _.isEqual @attributes[attr], val
				@attributes[attr] = val
				changed = true

				@trigger "change:" + attr, options if not options.silent

		@trigger "change", options if changed and not options.silent

		return this
