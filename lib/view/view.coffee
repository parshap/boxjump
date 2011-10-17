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

		@el or= document.createElement @tagName

		@el.id = @id if @id
		@el.className = @className if @className

		@initialize()

	initialize: ->

	getClasses: ->
		if @el.className then @el.className.split(/\s+/) else []

	addClass: (value) ->
		classes = @getClasses()

		classes.push value if value not in classes

		@el.className = classes.join(" ")

	removeClass: (value) ->
		classes = @getClasses()

		if (index = classes.indexOf value) > -1
			classes.splice classes.indexOf(value), 1

		@el.className = classes.join(" ")
