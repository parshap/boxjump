
class BoxList extends G.List


class Box extends G.Model
	sides: ->
		@objects()[0].sides()


class BoxView extends G.View
	initialize: ->
		@container.bind "drag", (el, moved) =>
			if el == @el
				@model.move moved, models.filter (model) => @model != model

		@model.bind "collide", =>
			@el.className = "collided"

		@model.bind "nocollide", =>
			@el.className = ""

		@model.bind "change", =>
			sides = @model.sides()

			@el.style.left = sides.left + "px";
			@el.style.top = sides.top + "px";
			@el.style.width = @model.get("width") + "px";
			@el.style.height = @model.get("height") + "px";

			doCollisions()


class ContainerView extends G.View
	initialize: ->
		@_dragToCreate()
		@_dragToMove()

		@models.bind "add", (model) =>
			@el.appendChild new BoxView({
				model: model
				container: @
			}).el

	_getPos: (e) ->
		return {
			x: e.clientX - @el.offsetLeft - @el.clientLeft,
			y: e.clientY - @el.offsetTop - @el.clientTop
		}

	_dragToCreate: ->
		box = null
		downPos = null

		@el.addEventListener "mousedown", (e) =>
			if e.target == @el and e.button == 0
				@models.add box = new Box()
				downPos = @_getPos(e)

		@el.addEventListener "mouseup", (e) =>
			box = null

		@el.addEventListener "mousemove", (e) =>
			if box
				pos = @_getPos(e)

				box.set {
					width: Math.abs(pos.x - downPos.x)
					height: Math.abs(pos.y - downPos.y)
					x: (pos.x + downPos.x) / 2
					y: (pos.y + downPos.y) / 2
				}

	_dragToMove: ->
		el = null
		pos = null

		@el.addEventListener "mousedown", (e) =>
			if e.target != @el and e.button == 0
				el = e.target
				pos = @_getPos(e)

		@el.addEventListener "mouseup", (e) =>
			el = null

		@el.addEventListener "mousemove", (e) =>
			if el
				newPos = @_getPos(e)

				container.trigger "drag", el, {
					x: newPos.x - pos.x,
					y: newPos.y - pos.y
				}

				pos = newPos


doCollisions = ->
	models.forEach (model) ->

		colliding = model.colliding models.filter (oModel) -> oModel != model

		model.trigger if colliding.length then "collide" else "nocollide"


models = new BoxList()
container = new ContainerView {
	models: models
	el: document.getElementById "container"
}

models.add bbox = new Box()
bbox.set {
	x: 400
	y: 900
	width: 400
	height: 300
}

models.add box = new Box()
box.set {
	x: 200
	y: 200
	width: 80
	height: 80
}

setInterval (->
	box.move { x: 17, y: 233 }, [bbox]
), 500
