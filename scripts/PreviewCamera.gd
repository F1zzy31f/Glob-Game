extends Camera2D

@export var margin = Vector2(128, 128)
@export var zoom_speed = 2

func _process(delta):
	var target_positions = []
	for child in Peers.get_children():
		if not child.is_class("MultiplayerSpawner"):
			target_positions.append(child.global_position)
	
	if target_positions.size() < 1: return
	
	var p = Vector2.ZERO
	for pos in target_positions:
		p += pos
	p /= target_positions.size()
	position = p
	
	var r = Rect2(position, Vector2.ONE)
	for pos in target_positions:
		r = r.expand(pos)
	r = r.grow_individual(margin.x, margin.y, margin.x, margin.y)
	var z
	if r.size.x > r.size.y * get_viewport_rect().size.aspect():
		z = r.size.x / get_viewport_rect().size.x
	else:
		z = r.size.y / get_viewport_rect().size.y
	zoom = lerp(zoom, Vector2.ONE / z, zoom_speed * delta)
