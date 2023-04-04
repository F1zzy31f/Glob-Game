extends Item

@export var damage = 10
@export var firerate = 10
@export var pellet_count = 1
@export var accuracy = 3
@export var mag_size = 30
@export var reload_time = 2
@export var bullet_impact_particles = preload("res://scenes/BulletImpactParticles.tscn")

var can_fire = true
var is_reloading = false
var mag_contents = 0

@onready var raycast = $Raycast
@onready var tracer = $Tracer
@onready var fire_sound = $FireSound
@onready var player = $"../../.."

func _ready():
	tracer.top_level = true
	reset()

func reset():
	mag_contents = mag_size

func on_equip():
	is_equip = true

func on_unequip():
	is_equip = false

func get_item_info():
	var item_info = str(name) + ": "
	
	if is_reloading:
		item_info += "Reloading..."
	else:
		item_info += str(mag_contents) + " / "+ str(mag_size)
	
	return item_info

func _process(_delta):
	visible = is_equip
	
	if not is_equip: return
	if not player.is_multiplayer_authority(): return
	
	if Input.is_action_pressed("primary_fire") and can_fire and not is_reloading and mag_contents > 0:
		can_fire = false
		
		mag_contents -= 1
		
		for i in pellet_count:
			raycast.rotation_degrees = randf_range(-accuracy, accuracy)
			raycast.force_raycast_update()
			
			if raycast.is_colliding() and raycast.get_collider():
				if raycast.get_collider().is_in_group("Hurtable"):
					if (raycast.get_collider().team_index != player.team_index):
						raycast.get_collider().hurt.rpc(damage)
				if raycast.get_collider() is TileMap and damage > 16:
					raycast.get_collider().erase_cell(0, raycast.get_collider().local_to_map(raycast.get_collision_point() - raycast.get_collision_normal()))
				draw_tracer(raycast.get_collision_point(), raycast.get_collision_normal())
				draw_tracer.rpc(raycast.get_collision_point(), raycast.get_collision_normal())
		
		await get_tree().create_timer(float(1) / firerate).timeout
		can_fire = true
	
	if Input.is_action_just_pressed("reload") and not is_reloading:
		is_reloading = true
		
		await get_tree().create_timer(reload_time).timeout
		
		mag_contents = mag_size
		
		is_reloading = false

@rpc("any_peer")
func draw_tracer(collision_point, collision_normal):
	fire_sound.play()
	
	var bullet_impact = bullet_impact_particles.instantiate()
	Temporary.add_child(bullet_impact)
	bullet_impact.global_position = collision_point
	bullet_impact.look_at(bullet_impact.global_position + collision_normal)
	bullet_impact.emitting = true
	
	var new_tracer = tracer.duplicate()
	add_child(new_tracer)
	new_tracer.clear_points()
	new_tracer.add_point(global_position)
	new_tracer.add_point(collision_point)
	
	await get_tree().create_timer(0.05).timeout
	new_tracer.queue_free()
	
	await get_tree().create_timer(10).timeout
	bullet_impact.queue_free()
