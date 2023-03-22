extends Control

var player

func _ready():
	player = get_node("/root/Peers/" + str(name))
	get_child(0).text = player.username + ": " + str(player.score)
	modulate = Color.from_hsv(float(player.team_index) / Globals.team_count, 0.6, 1)
