@tool
extends Node2D

enum AbilityType{ Active, Passive, Ultimate }
enum AbilityStyle{ Projectile, Buff, Summon }

@export var type = AbilityType.Active
@export var style = AbilityStyle.Projectile

@export_group("Types")

@export_subgroup("Active")
@export var active_recharge = 32
@export_subgroup("Ultimate")
@export var ultimate_charge = true

@export_group("Styles")

@export_subgroup("Projectile")
@export var projectile_scene = preload("res://scenes/Fireball.tscn")
@export var projectile_speed = 256
@export_subgroup("Buff")
@export var buff_duration = 16
@export var buff_health = 0
@export var buff_speed = 0
@export var buff_jump_height = 0
@export_subgroup("Summon")
@export var summon_scene = preload("res://scenes/Goblin.tscn")
@export var summon_count = 1

@onready var player = $"../.."

var recharge_timer = 0

func _ready():
	recharge_timer = active_recharge

func _process(delta):
	if not is_multiplayer_authority(): return
	
	recharge_timer += delta

func activate():
	match type:
		AbilityType.Active:
			if recharge_timer > active_recharge:
				recharge_timer = 0
				
				match style:
					AbilityStyle.Projectile:
						projectile.rpc(multiplayer.get_unique_id(), (global_position - get_global_mouse_position()).normalized().limit_length(1))
					
					AbilityStyle.Buff:
						buff()
					
					AbilityStyle.Summon:
						summon.rpc(multiplayer.get_unique_id())
		
		AbilityType.Ultimate:
			if ultimate_charge:
				ultimate_charge = false
				match style:
						AbilityStyle.Projectile:
							projectile.rpc(multiplayer.get_unique_id(), (global_position - get_global_mouse_position()).normalized().limit_length(1))
						
						AbilityStyle.Buff:
							buff()
						
						AbilityStyle.Summon:
							for i in summon_count:
								summon.rpc(multiplayer.get_unique_id())

@rpc("any_peer", "call_local")
func projectile(owner_id, aim_normal):
	if multiplayer.get_unique_id() != 1: return
	
	var new_projectile = projectile_scene.instantiate()
	new_projectile.name = str(owner_id) + "_" + new_projectile.name
	new_projectile.global_position = global_position - (aim_normal * 24)
	
	Temporary.add_child(new_projectile, true)
	
	new_projectile.set_axis_velocity(-aim_normal * projectile_speed)

func buff():
	player.health += buff_health
	player.speed += buff_speed
	player.jump_height += buff_jump_height
	
	await get_tree().create_timer(buff_duration).timeout
	
	player.health -= buff_health
	player.speed -= buff_speed
	player.jump_height -= buff_jump_height

@rpc("any_peer", "call_local")
func summon(owner_id):
	if multiplayer.get_unique_id() != 1: return
	
	var new_summon = summon_scene.instantiate()
	new_summon.name = str(owner_id) + "_" + new_summon.name
	
	Temporary.add_child(new_summon, true)
	
