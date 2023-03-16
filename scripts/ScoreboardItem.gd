extends Label

var player

func _ready():
	player = get_node("/root/Main/" + str(name))

func _process(delta):
	text = str(name) + ": " + str(player.score)
