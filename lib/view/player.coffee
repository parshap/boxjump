View = require("./view").View


exports.PlayerView = class PlayerView extends View
	className: "player"

	initialize: ->
		@el.appendChild new HealthView(player: @player).el
		@el.appendChild new ArmView(player: @player).el

	update: ->
		sides = @player.body.sides()

		@el.style.left = @SCALE * sides.left + "px"
		@el.style.top = @SCALE * sides.top + "px"
		@el.style.width = @SCALE * @player.get("width") + "px"
		@el.style.height = @SCALE * @player.get("height") + "px"

	tick: (time, dt) ->
		@update()


class ArmView extends View
	className: "arm"


class HealthView extends View
	tagName: "meter"

	className: "health"

	attributes:
		min: 0
		max: 100
		optimum: 100
		high: 75
		low: 25
		value: 0

	initialize: ->
		for attr, value of @attributes
			@el.setAttribute attr, value

		@player.bind "change:health", => @update()

		@update()

	update: ->
		@el.value = @player.get "health"

