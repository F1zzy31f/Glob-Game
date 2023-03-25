extends RigidBody2D

@export var initialized = false

@onready var blast_radius = $BlastRadius

func _enter_tree():
	set_multiplayer_authority(int(name.split("_")[0]), true)

@rpc("any_peer", "call_local")
func initialize(spawn_position, spawn_velocity):
	if not is_multiplayer_authority(): return
	
	initialized = true
	
	global_position = spawn_position
	linear_velocity = spawn_velocity

func _on_body_entered(_body):
	if not initialized: return
	
	queue_free()
	
	if not is_multiplayer_authority(): return
	
	for hit in blast_radius.get_overlapping_bodies():
		if hit.is_in_group("Hurtable"):
			hit.hurt.rpc(32)
	
