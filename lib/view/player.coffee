View = require("./view").View


exports.PlayerView = class PlayerView extends View
	className: "player direction-right"

	initialize: ->
		@el.appendChild new HealthView(player: @player).el
		@el.appendChild new ArmView(player: @player).el

		# Facing direction
		@player.bind "change:direction", =>
			direction = @player.get("direction")

			# Right
			if direction > 0
				@removeClass "direction-left"
				@addClass "direction-right"

			# Left
			else if direction
				@removeClass "direction-right"
				@addClass "direction-left"

		# Jump animation
		@player.bind "pre-jump", =>
			@addClass "jumping"

			# Remove jumping class after some time
			setTimeout (=>
				@removeClass "jumping"
			), 300

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

	initialize: ->
		@player.bind "predict-action", (action) =>
			@predictPunch() if action.id == 0x10

		@player.bind "schedule-action", (action) =>
			@predictPunch() if action.id == 0x10

		@player.bind "action", (action) =>
			@punch() if action.id == 0x10


	predictPunch: ->
		@addClass "pending"

	# Punch animation
	punch: ->
		@addClass "pending"

		setTimeout (=>
			@removeClass "pending"
			@addClass "punching"

			setTimeout (=>
				@removeClass "punching"
			), 2000
		), 300


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

