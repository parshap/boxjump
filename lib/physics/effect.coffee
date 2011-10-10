Vector = require("./vector").Vector


exports.Effect = class Effect extends Vector
	active: true

	enable: ->
		@active = true
		return this

	disable: ->
		@active = false
		return this
