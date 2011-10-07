var client = require("./lib/client"),
	gameClient = window.game = new client.Application()

gameClient.connect().start()
