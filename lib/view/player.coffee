View = require("./view").View


exports.PlayerView = class PlayerView extends View
	className: "player"

	update: ->
		sides = @player.body.sides()

		@el.style.left = @SCALE * sides.left + "px"
		@el.style.top = @SCALE * sides.top + "px"
		@el.style.width = @SCALE * @player.get("width") + "px"
		@el.style.height = @SCALE * @player.get("height") + "px"

	tick: (time, dt) ->
		@update()
