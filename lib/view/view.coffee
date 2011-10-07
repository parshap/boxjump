Event = require("../event").Event


exports.View = class View extends Event
	SCALE: 50

	tagName: "div"

	id: null

	className: null

	constructor: (options = {}) ->
		super()

		for attr, val of options
			@[attr] = val

		@el or= document.createElement "div"

		@el.id = @id if @id
		@el.className = @className if @className

		@initialize()

	initialize: ->
