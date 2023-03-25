extends RigidBody2D

@export var dormant = false

@onready var blast_radius = $BlastRadius

func _enter_tree():
	set_multiplayer_authority(int(name.split("_")[0]), true)

func _process(delta):
	visible = !dormant

func _on_body_entered(body):
	if not is_multiplayer_authority(): return
	
	for hit in blast_radius.get_overlapping_bodies():
		if hit.is_in_group("Hurtable"):
			hit.hurt.rpc(32)
	
	dormant = true
	
	await get_tree().create_timer(1).timeout
	
	queue_free()
