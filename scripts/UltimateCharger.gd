extends RigidBody2D

@export var dormant = false

func _on_detection_area_body_entered(body):
	if body and body.is_in_group("Player"):
		if body.charge_ultimate():
			on_use.rpc()

@rpc("any_peer", "call_local")
func on_use():
	dormant = true
	
	await get_tree().create_timer(1).timeout
	
	queue_free()
