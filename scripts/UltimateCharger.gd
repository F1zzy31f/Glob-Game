extends RigidBody2D

@export var explosion_effect = preload("res://scenes/ExplosionEffect(32).tscn")

@onready var pickup_sound = $PickupSound

func _on_detection_area_body_entered(body):
	if body and body.is_in_group("Player"):
		if body.charge_ultimate():
			destroy.rpc()

@rpc("any_peer", "call_local")
func destroy():
	pickup_sound.play()
	
	visible = false
	set_deferred("freeze", true)
	get_node("CollisionShape2D").set_deferred("disabled", true)
	
	var new_explosion = explosion_effect.instantiate()
	new_explosion.global_position = global_position
	Temporary.add_child(new_explosion)
	
	await get_tree().create_timer(1).timeout
	
	queue_free()
