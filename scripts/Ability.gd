@tool
extends Node2D

enum AbilityType{ Active, Passive, Ultimate }
enum AbilityStyle{ Projectile, Buff, Debuff, Area, Summon }

@export var type = AbilityType.Active
@export var style = AbilityStyle.Projectile

@export_group("Active")
@export var active_recharge = 32

@export_subgroup("Projectile")
@export var projectile_scene = preload("res://scenes/Fireball.tscn")
@export var projectile_speed = 256

@export_subgroup("Buff")
@export var buff_duration = 16
@export var buff_health = 0
@export var buff_speed = 0
@export var buff_jump_height = 0

@onready var player = $"../.."

var recharge_timer = 0

func _ready():
	recharge_timer = active_recharge

func _process(delta):
	recharge_timer += delta

func activate():
	match type:
		AbilityType.Active:
			if recharge_timer > active_recharge:
				recharge_timer = 0
				
				match style:
					AbilityStyle.Projectile:
						var new_projectile = projectile_scene.instantiate()
						var mouse_normal = (global_position - get_global_mouse_position()).normalized().limit_length(1)
						print(mouse_normal)
						Temporary.add_child(new_projectile)
						new_projectile.global_position = global_position - (mouse_normal * 24)
						new_projectile.set_axis_velocity(-mouse_normal * projectile_speed)
					
					AbilityStyle.Buff:
						print(player)
						player.health += buff_health
						player.speed += buff_speed
						player.jump_height += buff_jump_height
						
						await get_tree().create_timer(buff_duration).timeout
						
						player.health -= buff_health
						player.speed -= buff_speed
						player.jump_height -= buff_jump_height
