Event = require("../event").Event
Vector = require("./vector").Vector
Effect = require("./effect").Effect

exports.Body = class Body extends Event
	world: null
	# List of known states
	states: null
	velocity: null
	impulse: null
	force: null
	fallAffinity: 1.0
	# Keep track of the last move vector for networking reasons
	_lastMovedV: null

	constructor: (@position = Vector.zero()) ->
		super()

		@world = null # @TODO: Collision logic expects @world
		@states = []
		@velocity = Vector.zero()
		@impulse = Vector.zero()
		@force = Vector.zero()
		@lastVelocity = @_lastMovedV = Vector.zero()

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

			@position.x = @states[0].x * (1 - k)
			@position.x += @states[1].x * k

			@position.y = @states[0].y * (1 - k)
			@position.y += @states[1].y * k

			return true

		return false

	# Tick physics world forward dt
	_move: (dt) ->
		# Calculate a new velocity based on the total force and a new
		# position based on the change in velocity over the last time
		# period (using the trapezoidal rule)
		# pos = pos + 0.5 * v * dt
		# v = v + a * dt
		# pos = pos + 0.5 * v * dt
		# OR pos = (2v + a * dt) * 0.5 * dt
		desired = Vector.zero()
		desired.add @velocity
		@velocity.add @force.clone().mul dt
		desired.add @velocity
		desired.mul 0.5
		desired.add @impulse
		desired.mul dt

		# Multiply movement by fallAffinity if we're falling
		desired.y *= @fallAffinity if desired.y > 0

		# Add correction
		if @_correction
			# @TODO Max correction per frame
			desired.add @_correction
			@_correction.set x: 0, y: 0

		# Perform collisions
		origDesired = desired.clone()
		for body in @world.bodies.array when body isnt @
			@collide body, desired

		# Airborne unless y-axis movement was restricted
		@airborne = not (desired.y < origDesired.y)
		# Reset velocity if we landed
		@velocity.x = 0 if desired.x is 0
		@velocity.y = 0 if desired.y is 0
		@_lastMovedV.set(desired).div dt
		@position.add desired

	collide: (body, desired) ->
		throw new Error "Not Implemented"
