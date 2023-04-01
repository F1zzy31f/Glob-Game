extends RigidBody2D

@export var initialized = false
@export var explosion_effect = preload("res://scenes/ExplosionEffect.tscn")

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
	if not is_multiplayer_authority() or not initialized: return
	destroy.rpc()
	
	for hit in blast_radius.get_overlapping_bodies():
		if hit.is_in_group("Hurtable"):
			hit.hurt.rpc(32)

@rpc("any_peer", "call_local")
func destroy():
	visible = false
	set_deferred("freeze", true)
	get_node("CollisionShape2D").set_deferred("disabled", true)
	
	var new_explosion = explosion_effect.instantiate()
	new_explosion.global_position = global_position
	Temporary.add_child(new_explosion)
	
	await get_tree().create_timer(1).timeout
	
	queue_free()
