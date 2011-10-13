Wall = require("./wall").Wall


module.exports = -> [
	# Air platform
	Wall.fromPoints { x: 1.5, y: 3.6 }, { x: 13, y: 4 }

	# Bottom
	Wall.fromPoints { x: -100, y: 12.6 }, { x: 120, y: 13 }

	# Right-side stepping platform
	Wall.fromPoints { x: 16, y: 8 }, { x: 120, y: 8.5 }

	# Left-side stump
	Wall.fromPoints { x: 5, y: 11 }, { x: 9, y: 13 }

	# Left wall
	Wall.fromPoints { x: -1, y: -100 }, { x: 0, y: 100 }

	# Right wall
	Wall.fromPoints { x: 20.48, y: -100 }, { x: 22, y: 100 }
]
