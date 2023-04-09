extends RigidBody2D
class_name Projectile

@export var initialized = false

func _enter_tree():
	set_multiplayer_authority(int(name.split("_")[0]), true)

@rpc("any_peer", "call_local")
func initialize(spawn_position, spawn_velocity):
	if not is_multiplayer_authority(): return
	
	initialized = true
	
	global_position = spawn_position
	linear_velocity = spawn_velocity
