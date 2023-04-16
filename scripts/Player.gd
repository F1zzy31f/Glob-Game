extends CharacterBody2D

@export var dormant = false
@export var username = ""

@export var health = 32
@export var shield = 0

@export var speed = 96
@export var jump_height = 47
@export var jump_times = 1
@export var climb_speed = 128
@export var regen_delay = 9
@export var regen_time = 32
@export var damage_multiplier = float(1)

@export var item : Node = null
@export var team_index = 0
@export var scoreboard_item = preload("res://scenes/ScoreboardItem.tscn")
@export var inventory_item = preload("res://scenes/InventoryItem.tscn")
@export var explosion_effect = preload("res://scenes/ExplosionEffect(32).tscn")
@export var item_pickup = preload("res://scenes/ItemPickup.tscn")

@export var score = 0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $Sprite
@onready var camera = $Camera
@onready var overhead_username = $OverheadUI/Username
@onready var audio_listener = $Camera/AudioListener
@onready var hand_pivot = $HandPivot
@onready var hand = $HandPivot/Hand
@onready var passive_abilities = $Abilities/Passive
@onready var active_abilities = $Abilities/Active
@onready var ultimate_abilities = $Abilities/Ultimate
@onready var ui = $CanvasLayer/UI
@onready var time_till_start = $CanvasLayer/UI/TimeTillStart
@onready var healthbar = $CanvasLayer/UI/Healthbar
@onready var shieldbar = $CanvasLayer/UI/Shieldbar
@onready var item_info = $CanvasLayer/UI/ItemInfo
@onready var inventory = $CanvasLayer/UI/Inventory
@onready var ability_ui_active1 = $CanvasLayer/UI/Abilities/Active1
@onready var ability_ui_active2 = $CanvasLayer/UI/Abilities/Active2
@onready var ability_ui_ultimate = $CanvasLayer/UI/Abilities/Ultimate
@onready var scoreboard = $CanvasLayer/UI/Scoreboard
@onready var hurt_sound = $HurtSound

var item_primary = null
var item_secondary = null

var ability_passive = null
var ability_active1 = null
var ability_active2 = null
var ability_ultimate = null

var is_dead = false
var on_climbable = false
var recent_damager = null

var regen_timer = 0
var jumps_left = 0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int(), true)

func _ready():
	disappear()
	
	if not is_multiplayer_authority(): return
	
	username = Network.username
	overhead_username.text = username
	
	team_index = randi_range(0, Globals.team_count - 1)
	
	ability_passive = passive_abilities.get_node(Network.ability_passive)
	ability_active1 = active_abilities.get_node(Network.ability_active1)
	ability_active2 = active_abilities.get_node(Network.ability_active2)
	ability_ultimate = ultimate_abilities.get_node(Network.ability_ultimate)
	
	item_primary = hand.get_node("Fists")
	item_secondary = hand.get_node("Fists")
	
	item = item_primary
	change_item.rpc(null, str(item.name))
	
	ability_passive.activate()
	
	ui.visible = true
	camera.enabled = true
	camera.make_current()
	audio_listener.make_current()
	
	global_position = get_node("/root/Map/Spawns").get_child(randi_range(0, get_node("/root/Map/Spawns").get_child_count() - 1)).global_position
	
	Network.on_start_game.connect(self.on_game_start)

func on_game_start():
	appear.rpc()

func _process(delta):
	if not is_multiplayer_authority() : return
	
	if is_dead and recent_damager:
		camera.global_position = Peers.get_node(str(recent_damager)).global_position
	else:
		camera.position = Vector2.ZERO
	
	# UI
	time_till_start.text = str(Network.time_till_start) + "..."
	if Network.time_till_start <= 0:
		time_till_start.visible = false
	
	healthbar.value = health
	shieldbar.value = shield
	
	$CanvasLayer/UI/TeamIndex.text = "Team: " + str(team_index + 1)
	
	item_info.text = item.get_item_info()
	for child in inventory.get_children():
		child.free()
		
	var primary_item = inventory_item.instantiate()
	primary_item.name = item_primary.name
	primary_item.get_child(0).text = str(item_primary.name)
	primary_item.self_modulate = Color.from_hsv(0, 0, 0.4) if item_primary.is_equip else Color.from_hsv(0, 0, 0.3)
	inventory.add_child(primary_item)
	
	var secondary_item = inventory_item.instantiate()
	secondary_item.name = item_secondary.name
	secondary_item.get_child(0).text = str(item_secondary.name)
	secondary_item.self_modulate = Color.from_hsv(0, 0, 0.4) if item_secondary.is_equip else Color.from_hsv(0, 0, 0.3)
	inventory.add_child(secondary_item)
	
	ability_ui_active1.get_child(0).text = ability_active1.name
	ability_ui_active1.get_child(1).value = ability_active1.recharge_timer
	ability_ui_active1.get_child(1).max_value = ability_active1.active_recharge
	
	ability_ui_active2.get_child(0).text = ability_active2.name
	ability_ui_active2.get_child(1).value = ability_active2.recharge_timer
	ability_ui_active2.get_child(1).max_value = ability_active2.active_recharge
	
	ability_ui_ultimate.get_child(0).text = ability_ultimate.name
	ability_ui_ultimate.get_child(1).value = 1 if ability_ultimate.ultimate_charge else 0
	
	if not Network.game_started : return
	
	# Update
	regen_timer += delta
	
	if regen_timer > regen_delay:
		health += (delta * 32) / regen_time
		
	health = clamp(health, 0, 32)
	shield = clamp(shield, 0, 32)
	
	# Score
	Network.score = (100 * Network.kills) + (-50 * Network.deaths)
	score = Network.score
	
	# Abilities
	if not is_dead:
		if Input.is_action_just_pressed("ability_active_1"):
			ability_active1.activate()
		if Input.is_action_just_pressed("ability_active_2"):
			ability_active2.activate()
		if Input.is_action_just_pressed("ability_ultimate"):
			ability_ultimate.activate()
	
	# Drop Item
	if Input.is_action_just_pressed("drop_item"):
		if str(item.name) == "Fists": return
		
		if item == item_primary:
			item_primary = hand.get_node("Fists")
			change_item.rpc(null, "Fists")
		elif item == item_secondary:
			item_secondary = hand.get_node("Fists")
			change_item.rpc(null, "Fists")
		
		var mouse_normal = (global_position - get_global_mouse_position()).normalized().limit_length(1)
		drop_item.rpc(global_position - mouse_normal * 24, str(item.name), str(name) + "_ItemPickup_" + str(randi_range(1000, 9999)))

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	if not Network.game_started : return
	
	# Dying
	if health <= 0 or global_position.y > 64:
		if not is_dead:
			on_die.rpc()
	else:
		# Movement
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			jumps_left = jump_times
		
		if Input.is_action_pressed("jump") and on_climbable:
			velocity.y = -climb_speed
		elif Input.is_action_just_pressed("jump") and jumps_left > 0:
			jumps_left -= 1
			velocity.y = -sqrt(jump_height * 2 * gravity)
		
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * (speed * item.speed_multiplier)
			sprite.animation = "walk"
			sprite.flip_h = true if velocity.x > 0 else false
		else:
			sprite.animation = "idle"
			velocity.x = move_toward(velocity.x, 0, speed)
		
		move_and_slide()
		
		# Aiming
		hand_pivot.look_at(get_global_mouse_position())
		while hand_pivot.rotation_degrees > 360:
			hand_pivot.rotation_degrees -= 360
		while hand_pivot.rotation_degrees < 0:
			hand_pivot.rotation_degrees += 360
		hand.scale.y = -1 if hand_pivot.rotation_degrees > 90 and hand_pivot.rotation_degrees < 270 else 1
		
		# Items
		if Input.is_action_just_pressed("item_primary"):
			change_item.rpc(str(item.name), str(item_primary.name))
			item = item_primary
		elif Input.is_action_just_pressed("item_secondary"):
			change_item.rpc(str(item.name), str(item_secondary.name))
			item = item_secondary

@rpc("call_local")
func drop_item(pickup_position, item_name, pickup_name):
	var new_pickup = item_pickup.instantiate()
	new_pickup.name = pickup_name
	Temporary.add_child(new_pickup)
	
	new_pickup.initialize.rpc(pickup_position, item_name)

@rpc("call_local")
func on_die():
	# Explode
	var new_explosion = explosion_effect.instantiate()
	new_explosion.global_position = global_position
	Temporary.add_child(new_explosion)
	
	if not is_multiplayer_authority(): return
	
	is_dead = true
	
	# Stats
	var damager = Peers.get_node_or_null(str(recent_damager))
	if damager:
		damager.got_kill.rpc()
	Network.deaths += 1
	
	disappear.rpc()
	await get_tree().create_timer(4).timeout
	appear.rpc()
	
	# Reset
	global_position = get_node("/root/Map/Spawns").get_child(randi_range(0, get_node("/root/Map/Spawns").get_child_count() - 1)).global_position
	health = 32
	shield = 0
	
	for child in hand.get_children():
		child.reset()
	is_dead = false

@rpc("call_local")
func disappear():
	visible = false
	get_node("Collider").set_deferred("disabled", true)

@rpc("call_local")
func appear():
	visible = true
	get_node("Collider").set_deferred("disabled", false)

@rpc("any_peer")
func got_kill():
	Network.kills += 1

@rpc("call_local")
func change_item(old_node, new_node):
	if old_node:
		hand.get_node(old_node).on_unequip()
	if new_node:
		hand.get_node(new_node).on_equip()

@rpc("any_peer", "call_local")
func hurt(amount):
	hurt_sound.play()
	
	if not is_multiplayer_authority(): return
	
	recent_damager = multiplayer.get_remote_sender_id()
	
	amount *= damage_multiplier
	
	shield -= amount
	if shield < 0:
		health += shield
		shield = 0
		
	regen_timer = 0

@rpc("any_peer", "call_local")
func knockback(vector):
	velocity += vector

func charge_ultimate():
	if not is_multiplayer_authority() : return
	
	if ability_ultimate.ultimate_charge == false:
		ability_ultimate.ultimate_charge = true
		return true
	return false

func pickup_item(item_name):
	if str(item_primary.name) == "Fists":
		item_primary = hand.get_node(item_name)
		return true
	elif str(item_secondary.name) == "Fists":
		item_secondary = hand.get_node(item_name)
		return true
	
	return false

func update_scoreboard():
	for child in scoreboard.get_children():
		if not child.is_class("Timer"):
			child.free()
	
	var peers = []
	for child in Peers.get_children():
		if not child.is_class("MultiplayerSpawner"):
			peers.append(child)
	peers.sort_custom(func(a, b): return a.score > b.score)
	for child in peers:
		if not child.is_class("MultiplayerSpawner"):
			var new_item = scoreboard_item.instantiate()
			new_item.name = child.name
			scoreboard.add_child(new_item)

func _on_team_up_pressed():
	team_index = clamp(team_index + 1, 0, Globals.team_count - 1)
	$CanvasLayer/UI/TeamUp.release_focus()

func _on_team_down_pressed():
	team_index = clamp(team_index - 1, 0, Globals.team_count - 1)
	$CanvasLayer/UI/TeamDown.release_focus()

func _on_foot_body_entered(_area):
	on_climbable = true

func _on_foot_body_exited(_area):
	on_climbable = false


func _on_leave_pressed():
	Network.leave_server()
	
	for child in Temporary.get_children():
		child.queue_free()
	for child in Peers.get_children():
		child.queue_free()
	
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
