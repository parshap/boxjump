var world = new G.World();

function create() {
	var object = new G.Object(),
		div = document.createElement("div");

	object.bind("change", function() {
		div.style.left = object.left() + "px";
		div.style.top = object.top() + "px";
		div.style.width = rect.width() + "px";
		div.style.height = rect.height() + "px";
	});
}

function collision() {
}
