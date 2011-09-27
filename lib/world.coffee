G = window.G

# A 2d vector
class G.Vector
	@zero: -> return new @ 0, 0

	constructor: ({@x, @y}) ->

	equals: ({x, y}) ->	return @x == x and @y == y

	length: -> return Math.sqrt @x * @x + @y * @y

	add: ({x, y}) -> return new G.Vector @x + x, @y + y

	sub: ({x, y}) -> return new G.Vector @x - x, @y - y

	mul: (k) -> return new G.Vector @x * k, @y * k

	div: (k) -> return new G.vector @x / k, @y / k

	negate: -> return @mul -1

	normalize: -> return @div @length

	dot: ({x, y}) -> return @x * x + @y * y

	slope: -> return @y / @x

	toString: -> return "<#{@x},#{@y}>"


# G.Event
#
# Event class derived from Jeremy Ashkenas' Backbone.js and Jerome
# Etienne's microevents.js.
# https://github.com/documentcloud/backbone
# https://raw.github.com/jeromeetienne/microevent.js
class G.Event
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
			@_callbacks[name] = (b for cb in @_callbacks[name] when cb != callback)

		return this

	trigger: (name) ->
		return this if not @_callbacks[name]

		args = Array.prototype.slice.call(arguments, 1)
		callback.apply(null, args) for callback in @_callbacks[name]

		return this


class G.Model extends G.Event
	defaults:
		x: 0
		y: 0
		width: 0
		height: 0

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

	colliding: (models) ->
		# The "this" model's objects
		tObjects = @objects()
		colliding = []

		# For each of the models we're testing against
		models.forEach (model) ->
			# The "other" model's objects
			oObjects = model.objects()

			# For each of "this" model's objects
			for tObject in tObjects
				# If "this" model's object is colliding with one of the
				# "other" model's objects, this model is colliding
				if tObject.colliding(oObjects).length
					colliding.push model
					break

		return colliding

	move: (v, models=[]) ->
		console.log "attempting to move: ", v.x, v.y
		return if v.x == 0 and v.y == 0

		# Translated objects
		tObjects = (object.translate(v) for object in @objects())

		# List of objects we would collide with
		collisions = []

		# Get the objects of the first model we collide with
		models.forEach (model) =>
			return if collisions.length

			oobjects = model.objects()

			for translated in tObjects
				collisions = translated.colliding oobjects
				break if collisions.length

		if collisions.length > 1
			console.log "Denying complex movement"
			return

		if collision = collisions[0]
			# @todo: prevent infinite recursiong
			return @move object.resolve(v, collision), models

		@set {
			x: @get("x") + v.x
			y: @get("y") + v.y
		}

	objects: ->
		return [
			new G.Physics.Rect @attributes.x, @attributes.y, @attributes.width, @attributes.height
		]


class G.View extends G.Event
	tagName: "div"

	constructor: (options = {}) ->
		super()

		@el or= document.createElement "div"

		for attr, val of options
			@[attr] = val

		@initialize()

	initialize: ->


class G.List extends G.Event
	constructor: (options = {}) ->
		super()

		@things = []

		for attr, val of options
			@[attr] = val

	add: (thing, options = {}) ->
		@things.push thing

		@trigger "add", arguments... if not options.silent

		return this

	remove: (thing, options = {}) ->
		@things.splice @things.indexOf(thing), 1

		@trigger "remove", arguments... if not options.silent

		return this

	forEach: ->
		@things.forEach(arguments...)

	filter: (test) ->
		return {
			forEach: (callback) =>
				@things.forEach ->
					callback arguments... if test arguments...
		}


class G.World
	constructor: (models = []) ->
		@models = new G.List(models)

	add: (model) ->
		model.world = @
		@models.add model

		return this

	remove: (model) ->
		model.world = null

		@models.remove model

		return this

	objects: ->
		objects = []

		@models.forEach (model) ->
			objects.push model.objects...

		return objects
