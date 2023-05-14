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
		pickup_sound.play()
		if body.is_multiplayer_authority():
			body.ammo_light = 128
			body.ammo_medium = 256
			body.ammo_heavy = 64
