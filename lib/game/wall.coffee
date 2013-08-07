physics = require "../physics"
Model = require("../model").Model
List = require("../list").List
Vector = require("../physics/vector").Vector

exports.Wall = class Wall extends Model
	defaults:
		x: 0
		y: 0
		width: 0
		height: 0

	@fromPoints: ({ x: x1, y: y1 }, { x: x2, y: y2 }) ->
		return new Wall attributes:
			x: (x1 + x2) / 2
			y: (y1 + y2) / 2
			width: Math.abs x2 - x1
			height: Math.abs y2 - y1

	initialize: ->
		@body = new physics.Rect(
			new Vector x: @get("x"), y: @get("y")
			new Vector x: @get("width") / 2, y: @get("height") / 2
		)

exports.WallList = class WallList extends List
