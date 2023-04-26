extends Node2D

@onready var map = $Map

var mirror_map

func _ready():
	mirror_map = map.duplicate()
	mirror_map.name = "MirrorMap"
	mirror_map.modulate = Color8(51, 51, 51)
	mirror_map.visible = false
	add_child(mirror_map)

func _process(delta):
	if multiplayer.get_unique_id() == 1: return
	
	if Network.get_local_player():
		if Network.get_local_player().mirrored:
			if map.global_position != Vector2(0, 8192):
				map.global_position = Vector2(0, 8192)
			map.visible = false
			if mirror_map.global_position != Vector2(0, 0):
				mirror_map.global_position = Vector2(0, 0)
			mirror_map.visible = true
		else:
			if map.global_position != Vector2(0, 0):
				map.global_position = Vector2(0, 0)
			map.visible = true
			if mirror_map.global_position != Vector2(0, 8192):
				mirror_map.global_position = Vector2(0, 8192)
			mirror_map.visible = false
