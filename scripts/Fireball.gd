extends RigidBody2D

@onready var blast_radius = $BlastRadius

func _ready():
	print(get_multiplayer_authority())

func _on_body_entered(body):
	queue_free()
	
	if not is_multiplayer_authority(): return
	
	for hit in blast_radius.get_overlapping_bodies():
		if hit.is_in_group("Hurtable"):
			hit.hurt.rpc(32)
