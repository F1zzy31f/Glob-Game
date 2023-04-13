extends Node2D

func _ready():
	call_deferred("setup_nav_server")

func setup_nav_server():
	var map = $Map.get_navigation_map(0)
	NavigationServer2D.map_set_active(map, true)
