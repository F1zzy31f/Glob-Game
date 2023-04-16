extends RigidBody2D

@export var initialized = false
@export var buff_health = 0
@export var buff_shield = 0

@rpc("any_peer", "call_local")
func initialize(pickup_position, buff_pickup_health, buff_pickup_shield):
	if not is_multiplayer_authority(): return
	
	initialized = true
	
	global_position = pickup_position
	buff_health = buff_pickup_health
	buff_shield = buff_pickup_shield

func _on_detection_area_body_entered(body):
	if not initialized: return
	
	if body and body.is_in_group("Player"):
		if body.is_multiplayer_authority():
			body.health += buff_health
			body.shield += buff_shield
			destroy.rpc()

@rpc("any_peer", "call_local")
func destroy():
	visible = false
	set_deferred("freeze", true)
	get_node("CollisionShape2D").set_deferred("disabled", true)
	
	await get_tree().create_timer(1).timeout
	
	queue_free()
