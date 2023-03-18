extends Label

var player

func _ready():
	player = get_node("/root/Peers/" + str(name))

func _process(delta):
	if player:
		text = str(name) + ": " + str(player.score)
