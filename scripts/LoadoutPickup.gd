extends RigidBody2D

@export var initialized = false

@onready var pickup_sound = $PickupSound

@rpc("any_peer", "call_local")
func initialize(pickup_position):
	if not is_multiplayer_authority(): return
	
	initialized = true
	
	global_position = pickup_position

func _on_detection_area_body_entered(body):
	if not initialized: return
	
	if body and body.is_in_group("Player"):
		if body.is_multiplayer_authority():
			if body.pickup_loadout():
				destroy.rpc()

@rpc("any_peer", "call_local")
func destroy():
	pickup_sound.play()
	
	visible = false
	set_deferred("freeze", true)
	get_node("CollisionShape2D").set_deferred("disabled", true)
	
	await get_tree().create_timer(1).timeout
	
	queue_free()
