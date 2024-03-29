@tool
extends Node2D

enum AbilityType{ Active, Passive, Ultimate }
enum AbilityStyle{ Projectile, Buff, Summon }

@export var type = AbilityType.Active
@export var style = AbilityStyle.Projectile

@export_group("Types")

@export_subgroup("Passive")
@export var activated_passive = false
@export_subgroup("Active")
@export var active_recharge = 0
@export_subgroup("Ultimate")
@export var ultimate_charge = false

@export_group("Styles")

@export_subgroup("Projectile")
@export var projectile_scene = preload("res://scenes/Fireball.tscn")
@export var projectile_speed = 0
@export var projectile_count = 0
@export var projectile_delay = float(0)
@export_subgroup("Buff")
@export var buff_permenent = false
@export var buff_duration = 16
@export var buff_health = 0
@export var buff_shield = 0
@export var buff_speed = 0
@export var buff_jump_height = 0
@export var buff_jump_times = 0
@export var buff_regen_delay = 0
@export var buff_regen_time = 0
@export var buff_damage_multiplier = float(0)
@export_subgroup("Summon")
@export var summon_scene = preload("res://scenes/Goblin.tscn")
@export var summon_count = 0
@export var summon_delay = float(0)

@onready var player = $"../../.."
@onready var ability_sound  = $"../../../AbilitySound"

var recharge_timer = 0

func _process(delta):
	if not is_multiplayer_authority(): return
	if not Network.game_started: return
	if Network.game_ended: return
	
	recharge_timer += delta

func activate():
	if player.dimension == Globals.dimension.Mirror: return
	
	match type:
		AbilityType.Passive:
			if not activated_passive:
				activated_passive = true
				activate_style()
		
		AbilityType.Active:
			if recharge_timer > active_recharge:
				player.shield += 8
				
				recharge_timer = 0
				activate_style()
		
		AbilityType.Ultimate:
			if ultimate_charge:
				player.shield += 16
				
				ultimate_charge = false
				activate_style()

func activate_style():
	play_sound.rpc()
	
	match style:
		AbilityStyle.Projectile:
			for i in projectile_count:
				var mouse_normal = (global_position - get_global_mouse_position()).normalized().limit_length(1)
				projectile.rpc(str(multiplayer.get_unique_id()) + "_" + name + str(randi_range(1000, 9999)), global_position - (mouse_normal * 24), mouse_normal)
				await get_tree().create_timer(projectile_delay).timeout
		
		AbilityStyle.Buff:
			buff()
		
		AbilityStyle.Summon:
			for i in summon_count:
				var mouse_normal = (global_position - get_global_mouse_position()).normalized().limit_length(1)
				summon.rpc(str(multiplayer.get_unique_id()) + "_" + name + str(randi_range(1000, 9999)), global_position - mouse_normal * 24, player.team_index)
				await get_tree().create_timer(summon_delay).timeout

@rpc("call_local")
func play_sound():
	ability_sound.play()

@rpc("any_peer", "call_local")
func projectile(spawn_name, spawn_position, aim_normal):
	var new_projectile = projectile_scene.instantiate()
	new_projectile.name = spawn_name
	Temporary.add_child(new_projectile)
	
	new_projectile.initialize.rpc(spawn_position, -aim_normal * projectile_speed)

func buff():
	player.health += buff_health
	player.shield += buff_shield
	player.speed += buff_speed
	player.jump_height += buff_jump_height
	player.jump_times += buff_jump_times
	player.regen_delay += buff_regen_delay
	player.regen_time += buff_regen_time
	player.damage_multiplier += buff_damage_multiplier
	
	await get_tree().create_timer(buff_duration).timeout
	
	if not buff_permenent:
		player.health -= buff_health
		player.shield -= buff_shield
		player.speed -= buff_speed
		player.jump_height -= buff_jump_height
		player.jump_times -= buff_jump_times
		player.regen_delay -= buff_regen_delay
		player.regen_time -= buff_regen_time
		player.damage_multiplier -= buff_damage_multiplier

@rpc("any_peer", "call_local")
func summon(spawn_name, spawn_position, spawn_team):
	var new_summon = summon_scene.instantiate()
	new_summon.name = spawn_name
	Temporary.add_child(new_summon)
	
	new_summon.initialize.rpc(spawn_position, spawn_team)
	
