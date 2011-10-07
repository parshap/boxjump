View = require("./view").View


exports.WallView = class WallView extends View
	className: "wall"

	initialize: ->
		sides = @wall.body.sides()

		@el.style.left = @SCALE * sides.left + "px"
		@el.style.top = @SCALE * sides.top + "px"
		@el.style.width = @SCALE * @wall.get("width") + "px"
		@el.style.height = @SCALE * @wall.get("height") + "px"
