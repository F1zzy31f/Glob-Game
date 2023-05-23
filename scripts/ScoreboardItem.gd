extends Control

func _ready():
	var team_index = 0
	for i in range(len(Globals.teams)):
		if Globals.teams[i]["name"] == str(name):
			team_index = i
	
	var score = 0
	for player in Peers.get_children():
		if not player.is_class("MultiplayerSpawner"):
			if player.team_index == team_index:
				score += player.score
	
	get_child(0).text = Globals.teams[team_index]["name"] + ": " + str(score)
	modulate = Globals.teams[team_index]["color"]
