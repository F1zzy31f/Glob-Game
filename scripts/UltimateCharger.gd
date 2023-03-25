extends RigidBody2D

func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		if body.charge_ultimate():
			queue_free()
