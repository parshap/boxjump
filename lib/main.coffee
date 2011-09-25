G = {}

# G.Event
#
# Event class derived from Backbone.js by Jeremy Ashkenas
# https://github.com/documentcloud/backbone
class G.Event
	constructor: ->
		@_callbacks = {}

	bind: (name, callback) ->
		@_callbacks[name] or= []
		@_callbacks[name].push(callback)

		return this

	unbind: (name, callback) ->
		if not name
			@_callbacks = {}
		else if not callback
			@_callbacks[name] = []
		else if @_callbacks[name]
			@_callbacks[name] = (b for cb in @_callbacks[name] when cb != callback)

		return this

	trigger: (name) ->
		return this if not @_callbacks[name]

		args = Array.prototype.slice.call(arguments, 1)
		callback.apply(null, args) for callback in @_callbacks[name]

		return this


class G.View extends G.Event
	tagName: "div"

	constructor: (el: @el, model: @model) ->
		super()

		@el or= document.createElement "div"

		@initialize()

	initialize: ->


class G.Model extends G.Event


class G.Collection extends G.Event
	constructor: ->
		@models or= []

		super()

	add: (model) ->
		@models.push model

		@trigger "add", arguments...

		return this

	remove: (model) ->
		@models = (m for m in @models when m != model)

		@trigger "remove", arguments...

		return this


class G.PlayerView extends G.View


class G.GameView extends G.View
	initialize: ->
		@model.players.bind "add", (player) => @addPlayer player

	addPlayer: (player) ->
		@el.appendChild (new G.PlayerView model: player).el


class G.Player extends G.Model


class G.Game extends G.Model
	constructor: (@el) ->
		@players = new G.Collection

		super()

	start: ->
		@view = new G.GameView el: @el, model: this

		@players.add new G.Player


game = new G.Game document.getElementById "game"
game.start()
