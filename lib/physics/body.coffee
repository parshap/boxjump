Event = require("../event").Event
Vector = require("./vector").Vector
Effect = require("./effect").Effect

exports.Body = class Body extends Event
	world: null

	# A list of known states
	states: null

	impulses: null

	forces: null

	velocity: null

	fallAffinity: 1.0

	_collidesCallbacks: null

	_contactsCallbacks: null

	_lastMovedV: null

	constructor: (@x = 0, @y = 0) ->
		super()

		@world = null # @TODO: Collision logic expects @world
		@states = []
		@velocity = new Vector
		@impulses = []
		@forces = []
		@_collidesCallbacks = []
		@_contactsCallbacks = []
		@_lastMovedV = new Vector

	tick: (time, dt) ->
		interpolated = @_interpolate time

		if not interpolated
			@_move dt

	# Sets the current state of the body (position) by interpolating
	# values at the given time from known states. Returns true if
	# successful.
	_interpolate: (time) ->
		# Put states in order by time (ascending)
		@states.sort (a, b) -> a.time - b.time

		# Get rid of any extra past states, we only need 1
		@states.shift() while @states.length > 1 and @states[1].time <= time

		# Interpolate if we have two states between our time
		if @states.length > 1 and @states[0].time <= time <= @states[1].time
			# Determine where time falls relative to the two states
			elapsed = time - @states[0].time
			k = elapsed / (@states[1].time - @states[0].time)

			@x = @states[0].x * (1 - k)
			@x += @states[1].x * k

			@y = @states[0].y * (1 - k)
			@y += @states[1].y * k

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

		# Multiply movement by fallAffinity if we're falling
		# @TODO: Are we always falling if we're moving downward?
		moveV.y *= @fallAffinity if moveV.y > 0

		# Attempts to move by the given move vector and returns the
		# actual move vector
		move = (moveV) =>
			moveV = new Vector moveV
			movedV = moveV.clone()

			collisions = null
			contacts = []
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
					if @colliding body
						collisions.push body

						if @_contacts body
							moved = false
							moveV = @resolve body, oldPosition
							movedV.add moveV
							contacts.push [body, moveV]

			# Expose colliding bodies
			# @TODO: Also pass the collision normal vector
			@trigger "collision", body for body in collisions

			# Expose resolved contacts
			# @TODO: There may be extra bodies in the list when one
			# contact resolves the movement to no longer be contacting
			# a previous contact.
			for [body, normalV] in contacts
				@trigger "contact", body, normalV

			# Airborne unless some contact constraint pushed us upward
			@airborne = ! contacts.some ([body, normalV]) -> normalV.y < 0

			# Reset vertical velocity if we've landed
			@velocity.y = 0 if not @airborne

			# Reset horizontal velocity too
			if contacts.some(([body, normalV]) -> normalV.x != 0)
				@velocity.x = 0

			return movedV

		movedV = @_lastMovedV = move moveV

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
