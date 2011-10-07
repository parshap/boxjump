var connect = require("connect"),
	browserify = require("browserify"),
	server = require("./lib/server"),

	httpServer = connect.createServer(),
	gameServer = new server.Application()


// Set up the game server
;(function() {
	gameServer.listen(httpServer).start()
}())


// Set up the http server
;(function() {
	httpServer.use(connect.static('public'))

	httpServer.use(browserify({
		entry: "./client.js",
		watch: true,
	}))

	httpServer.listen(8500)
}())
