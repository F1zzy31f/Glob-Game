extends Label

var player

func _ready():
	player = get_node("/root/Peers/" + str(name))
	text = str(name) + ": " + str(player.score)
