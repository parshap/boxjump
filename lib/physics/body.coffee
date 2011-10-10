Vector = require("./vector").Vector

exports.Body = class Body
	world: null

	# A list of known states
	states: null

	impulses: null

	forces: null

	velocity: null

	_collidesCallbacks: []

	_contactsCallbacks: []

	constructor: (@x = 0, @y = 0) ->
		@world = null # @TODO: Collision logic expects @world
		@states = []
		@velocity = new Vector
		@impulses = []
		@forces = []

	tick: (time, dt) ->
		interpolated = false
		oldPosition = new Vector { @x, @y }

		interpolated = @_interpolate time

		if not interpolated
			@_move dt

		movedV = new Vector({ @x, @y }).sub oldPosition

		@airborne = movedV.y != 0

		@velocity.x = 0 if movedV.x == 0
		@velocity.y = 0 if movedV.y == 0

		#if not sensor
		# resolve any broken contact constraints
		# fire any touch/notouch events (for changes)
		#if sensor
		# fire any collision/nocollision events (for changes)

	_interpolate: (time) ->
		return false if not @states.length

		# Get rid of any extra past states, we only need 1
		while (@states.length > 1) and (@states[1].time <= time)
			@states.shift()

		if @states.length > 1
			if @states[0].time <= time <= @states[1].time
				# console.log "interpolating", time, @states

				# Interpolate !
				elapsed = time - @states[0].time
				k = elapsed / (@states[1].time - @states[0].time)

				@x = @states[0].position.x * (1 - k)
				@x += @states[1].position.x * k

				@y = @states[0].position.y * (1 - k)
				@y += @states[1].position.y * k

				@velocity.x = @states[0].velocity.x * (1 - k)
				@velocity.x += @states[1].velocity.x * k

				@velocity.y = @states[0].velocity.y * (1 - k)
				@velocity.y += @states[1].velocity.y * k

				return true

		return false

	_move: (dt) ->
		oldPosition = new Vector { @x, @y }

		# Initialize a vector that will store the final move vector that
		# we will move by
		moveV = new Vector

		# Add up the total force
		tForceV = new Vector
		tForceV.add force for force in @forces when force.active

		# Calculate a new velocity based on the total force and a new
		# position based on the change in velocity over the last time
		# period (using the trapezoidal rule)
		#
		# pos = pos + 0.5 * v * dt
		# v = v + a * dt
		# pos = pos + 0.5 * v * dt
		moveV.add @velocity
		@velocity.add tForceV.mul(dt)
		moveV.add @velocity
		moveV.mul 0.5

		# Add impulses
		moveV.add impulse for impulse in @impulses when impulse.active

		moveV.mul dt

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
				if @_collides(body)and @colliding(body)
					collisions.push body

					if @_contacts body
						moved = false
						moveV = @resolve body, oldPosition
						break

	# Returns whether or not this body *can* collide with the given body
	_collides: (body) ->
		# A body cannot collide with itself
		return false if body is @

		# Return true if any of the collides callbacks return true
		for collides in @_collidesCallbacks
			if collides.call(null, body)
				return true

		return false

	# Returns whether or not there is a contact constraint between this body
	# and the given body
	_contacts: (body) ->
		# Return true if any of the contacts callbacks return true
		for contacts in @_contactsCallbacks
			if contacts.call(null, body)
				return true

		return false

	collides: (callback) ->
		@_collidesCallbacks.push callback

	contacts: (callback) ->
		@_contactsCallbacks.push callback

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
