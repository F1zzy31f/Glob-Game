extends Control

var player

func _ready():
	player = get_node("/root/Peers/" + str(name))
	get_child(0).text = player.username + ": " + str(player.score)
	self_modulate = Color.from_hsv(0, 0, 0.4) if player.is_multiplayer_authority() else Color.from_hsv(0, 0, 0.3)
