extends RigidBody2D

@onready var blast_radius = $BlastRadius

func _on_body_entered(body):
	if not is_multiplayer_authority(): return
	
	for hit in blast_radius.get_overlapping_bodies():
		if hit.is_in_group("Hurtable"):
			hit.hurt(32)
			hit.hurt.rpc(32)
	
	queue_free()
