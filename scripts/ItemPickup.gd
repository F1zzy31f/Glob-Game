extends RigidBody2D

@export var item_name = "AK-47"

func _on_detection_area_body_entered(body):
	if body and body.is_in_group("Player"):
		if body.is_multiplayer_authority():
			if body.pickup_item(item_name):
				destroy.rpc()

@rpc("any_peer", "call_local")
func destroy():
	visible = false
	set_deferred("freeze", true)
	get_node("CollisionShape2D").set_deferred("disabled", true)
	
	await get_tree().create_timer(1).timeout
	
	queue_free()
