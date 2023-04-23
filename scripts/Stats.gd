extends Node

var stats = {}

func _ready():
	var file = FileAccess.open("res://assets/stats.json", FileAccess.READ)
	stats = JSON.parse_string(file.get_as_text())
	file.close()
