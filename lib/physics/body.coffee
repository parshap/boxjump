Vector = require("./vector").Vector

exports.Body = class Body
	constructor: (@x = 0, @y = 0) ->
		@world = null # @TODO: Collision logic expects @world
		@velocity = new Vector
		@impulses = []
		@forces = []

	tick: (dt) ->
		# pos = pos + 0.5 * v * dt
		# v = v + a * dt
		# pos = pos + 0.5 * v * dt

		tImpulseV = new Vector
		tImpulseV.add impulse for impulse in @impulses when impulse.active

		tForceV = new Vector
		tForceV.add force for force in @forces when force.active

		moveV = new Vector
		moveV.add @velocity

		@velocity.add tForceV.mul(dt)

		moveV.add @velocity

		moveV.mul 0.5 * dt

		moveV.add tForceV.mul(dt)

		moveV.add tImpulseV.mul(dt)

		oldPosition = new Vector { @x, @y }
		collisions = []
		moved = false

		while not moved

			# Update position by move vector
			@x += moveV.x
			@y += moveV.y

			collisions = []
			moved = true

			# @TODO: Make sure we're not moving to a previous contact constraint

			# check for collisions at new position (and fire collision:before?)
			for body in @world.bodies.array
				# @TODO: Should these bodies collide?
				if body is @
					continue

				if @colliding body
					collisions.push body

					if true # @TODO isContactConstraint
						moved = false
						moveV = @resolve body, oldPosition
						break

		movedV = new Vector({ @x, @y }).sub oldPosition

		@airborne = movedV.y != 0

		@velocity.x = 0 if movedV.x == 0
		@velocity.y = 0 if movedV.y == 0

		#if not sensor
		# resolve any broken contact constraints
		# fire any touch/notouch events (for changes)
		#if sensor
		# fire any collision/nocollision events (for changes)

	# Returns whether or not this body is colliding with the given body
	colliding: (body) ->
		throw "Not Implemented"

	# Returns a movement vector to resolve the contact constraint against
	# the given body caused by the move from the given old position
	resolve: (body, oldPosition) ->
		throw "Not Implemented"

	impulse: (impulseV) ->
		effect = new Effect impulseV
		@impulses.push effect
		return effect

	force: (forceV) ->
		effect = new Effect forceV
		@forces.push effect
		return effect


class Effect extends Vector
	active: true

	enable: ->
		@active = true
		return this

	disable: ->
		@active = false
		return this
