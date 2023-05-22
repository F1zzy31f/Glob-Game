extends Node

var globapedia = {}

func _ready():
	var file = FileAccess.open("res://assets/globapedia.json", FileAccess.READ)
	globapedia = JSON.parse_string(file.get_as_text())
	file.close()
