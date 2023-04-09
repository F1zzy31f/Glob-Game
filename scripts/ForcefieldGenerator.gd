extends Projectile

@export var duration = 0

func _ready():
	await get_tree().create_timer(duration).timeout
	
	queue_free()
