extends Node2D

@onready var map = $Map

var mirror_map

func _ready():
	mirror_map = map.duplicate()
	mirror_map.name = "MirrorMap"
	mirror_map.modulate = Color8(51, 51, 51)
	add_child(mirror_map)

func _process(delta):
	if Network.get_local_player():
		if Network.get_local_player().mirrored:
			map.global_position = Vector2(0, 8192)
			mirror_map.global_position = Vector2(0, 0)
		else:
			map.global_position = Vector2(0, 0)
			mirror_map.global_position = Vector2(0, 8192)
