Event = require("../event").Event
Vector = require("./vector").Vector
chain = require("chainfn")

exports.Effect = class Effect extends Event
	enabled: false

	constructor: (enable, disable) ->
		super
		@on "enable", enable
		@on "disable", disable

		@enable()

	enable: chain ->
		if not @enabled
			@trigger "enable"
			@trigger "update"
			@enabled = true

	disable: chain ->
		if @enabled
			@trigger "disable"
			@trigger "update"
			@enabled = false
