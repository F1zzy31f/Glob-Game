extends Node2D

@onready var sprite = $Sprite2D

var target_position = null

func _process(delta):
	var canvas = get_canvas_transform()
	var top_left = -canvas.origin / canvas.get_scale()
	var size = get_viewport_rect().size / canvas.get_scale()
	var bounds = Rect2(top_left, size)
	
	sprite.global_position.x = clamp(global_position.x, bounds.position.x, bounds.end.x)
	sprite.global_position.y = clamp(global_position.y, bounds.position.y, bounds.end.y)
	
	var angle = (global_position - sprite.global_position).angle()
	sprite.global_rotation = angle
	
	sprite.visible = not bounds.has_point(global_position)
