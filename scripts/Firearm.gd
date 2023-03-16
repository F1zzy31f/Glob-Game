extends "res://scripts/Item.gd"

@export var damage = 10
@export var firerate = 10
@export var accuracy = 3
@export var bullet_impact_particles = preload("res://scenes/BulletImpactParticles.tscn")

var is_equip = false

var can_fire = true

@onready var raycast = $Raycast
@onready var tracer = $Tracer
@onready var fire_sound = $FireSound
@onready var player = $"../../.."

func _ready():
	tracer.top_level = true

func on_equip():
	is_equip = true

func on_unequip():
	is_equip = false

func _process(_delta):
	visible = is_equip
	
	if not is_equip: return
	if not player.is_multiplayer_authority(): return
	
	if Input.is_action_pressed("primary_fire") and can_fire:
		can_fire = false
		
		raycast.rotation_degrees = randf_range(-accuracy, accuracy)
		
		if (raycast.is_colliding()):
			if (raycast.get_collider().is_in_group("Hurtable")):
				if (raycast.get_collider().team_index != player.team_index || raycast.get_collider().team_index == -1):
					raycast.get_collider().hurt.rpc(damage)
			draw_tracer(raycast.get_collision_point(), raycast.get_collision_normal())
			draw_tracer.rpc(raycast.get_collision_point(), raycast.get_collision_normal())
		
		await get_tree().create_timer(float(1) / firerate).timeout
		can_fire = true

@rpc("any_peer")
func draw_tracer(collision_point, collision_normal):
	fire_sound.play()
	
	var bullet_impact = bullet_impact_particles.instantiate()
	Temporary.add_child(bullet_impact)
	bullet_impact.global_position = collision_point
	bullet_impact.look_at(bullet_impact.global_position + collision_normal)
	bullet_impact.emitting = true
	
	tracer.clear_points()
	tracer.add_point(global_position)
	tracer.add_point(collision_point)
	await get_tree().create_timer(0.05).timeout
	tracer.clear_points()
