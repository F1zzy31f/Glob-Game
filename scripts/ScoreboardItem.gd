extends Control

var player

func _ready():
	player = get_node("/root/Peers/" + str(name))
	get_child(0).text = player.username + ": " + str(player.score)
	modulate = Globals.teams[player.team_index]["color"]
