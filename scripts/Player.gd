extends CharacterBody2D

@export var dormant = false
@export var display_name = ""

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

@export var dimension = Globals.dimension.Material
@export var disappeared = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $Sprite
@onready var overhead_display_name = $OverheadUI/DisplayName
@onready var offscreen_marker = $OffscreenMarker
@onready var camera = $Camera
@onready var audio_listener = $Camera/AudioListener
@onready var hand_pivot = $HandPivot
@onready var hand = $HandPivot/Hand
@onready var passive_abilities = $Abilities/Passive
@onready var active_abilities = $Abilities/Active
@onready var ultimate_abilities = $Abilities/Ultimate
@onready var ui = $CanvasLayer/UI
@onready var start_countdown = $CanvasLayer/UI/StartCountdown
@onready var winner = $CanvasLayer/UI/Winner/Content
@onready var end_countdown = $CanvasLayer/UI/EndCountdown
@onready var healthbar = $CanvasLayer/UI/Healthbar
@onready var shieldbar = $CanvasLayer/UI/Shieldbar
@onready var item_info = $CanvasLayer/UI/ItemInfo
@onready var inventory = $CanvasLayer/UI/Inventory
@onready var ability_ui_active1 = $CanvasLayer/UI/Abilities/Active1
@onready var ability_ui_active2 = $CanvasLayer/UI/Abilities/Active2
@onready var ability_ui_ultimate = $CanvasLayer/UI/Abilities/Ultimate
@onready var scoreboard = $CanvasLayer/UI/Scoreboard
@onready var hurt_sound = $HurtSound
@onready var jump_sound = $JumpSound

var item_primary = null 
var item_secondary = null

var ammo_light = 24
var ammo_medium = 32
var ammo_heavy = 8

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
	#Input.set_custom_mouse_cursor(load("res://assets/Crosshair.png"))
	
	if is_multiplayer_authority():
		Network.local_player = self

func _ready():
	disappeared = true
	
	if not is_multiplayer_authority(): return
	
	display_name = Network.display_name
	overhead_display_name.text = display_name
	
	team_index = randi_range(0, len(Globals.teams) - 1)
	
	ability_passive = passive_abilities.get_node(Network.ability_passive)
	ability_active1 = active_abilities.get_node(Network.ability_active1)
	ability_active2 = active_abilities.get_node(Network.ability_active2)
	ability_ultimate = ultimate_abilities.get_node(Network.ability_ultimate)
	
	item_primary = hand.get_node("M1911")
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
	disappeared = false

func _process(delta):
	visible = true
	
	if health <= 0:
		visible = false
	
	sprite.sprite_frames = load("res://assets/animations/frames/player_%s.tres" % str(team_index))
	
	if multiplayer.get_unique_id() == 1: return
	
	if Network.local_player and dimension != Network.local_player.dimension:
		visible = false
	if disappeared:
		visible = false
	
	if Network.local_player:
		offscreen_marker.visible = team_index == Network.local_player.team_index
	offscreen_marker.modulate = Globals.teams[team_index]["color"]
	
	get_node("Collider").set_deferred("disabled", not visible)
	
	if not is_multiplayer_authority() : return
	
	if is_dead and recent_damager:
		global_position = Vector2(0, 0)
		camera.global_position = Peers.get_node(str(recent_damager)).global_position
	else:
		camera.position = Vector2.ZERO
	
	# UI
	start_countdown.visible = true
	start_countdown.text = str(Network.time_till_start) + "..."
	if Network.time_till_start == -1:
		start_countdown.text = "Intermission"
	if Network.time_till_start == 0:
		start_countdown.visible = false
	
	var minutes = max(floor(Network.time_till_end / 60), 0)
	var seconds = max(floor(fmod(Network.time_till_end, 60)), 0)
	var time = str(minutes) + ":"
	if seconds < 10:
		time += "0"
	time += str(seconds)
	
	end_countdown.text = time
	
	if Network.game_ended:
		winner.get_parent().visible = true
		winner.text = "Winner: " + Globals.teams[Network.winning_team]["name"]
	
	healthbar.value = health
	shieldbar.value = shield
	
	$CanvasLayer/UI/TeamName.text = "Team: " + Globals.teams[team_index]["name"]
	
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
	
	# Aiming
	var aim_axis = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if aim_axis.length() > 0.1:
		Input.warp_mouse(hand_pivot.get_global_transform_with_canvas().origin + (aim_axis * 128))
	
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
		
		if item_primary.two_handed == false:
			if item == item_primary:
				change_item.rpc(str(item_primary), "Fists")
				item_primary = hand.get_node("Fists")
			elif item == item_secondary:
				change_item.rpc(str(item_secondary), "Fists")
				item_secondary = hand.get_node("Fists")
		else:
			if item == item_primary:
				change_item.rpc(str(item_primary), "Fists")
				item_primary = hand.get_node("Fists")
				item_secondary = hand.get_node("Fists")
		
		var mouse_normal = (global_position - get_global_mouse_position()).normalized().limit_length(1)
		drop_item.rpc(global_position - mouse_normal * 24, str(item.name), str(name) + "_ItemPickup_" + str(randi_range(1000, 9999)))
		
		item = hand.get_node("Fists")
	
	if Input.is_action_just_pressed("mirror") and dimension !=  Globals.dimension.Mirror:
		dimension = Globals.dimension.Mirror
		
		await get_tree().create_timer(3).timeout
		
		dimension = Globals.dimension.Material

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	if not Network.game_started: return
	if Network.game_ended: return
	
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
			
			play_jump_sound.rpc()
		
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
	
	var mouse_normal = (global_position - get_global_mouse_position()).normalized().limit_length(1)
	
	if item_primary.droppable:
		drop_item.rpc(global_position - mouse_normal * 24, str(item_primary.name), str(name) + "_ItemPickup_" + str(randi_range(1000, 9999)))
	item_primary = hand.get_node("M1911")
	if item_secondary.droppable:
		drop_item.rpc(global_position - mouse_normal * 24, str(item_secondary.name), str(name) + "_ItemPickup_" + str(randi_range(1000, 9999)))
	item_secondary = hand.get_node("Fists")
	
	change_item.rpc(str(item.name), "M1911")
	item = hand.get_node("M1911")
	
	disappeared = true
	await get_tree().create_timer(4).timeout
	disappeared = false
	
	# Reset
	velocity = Vector2.ZERO
	global_position = get_node("/root/Map/Spawns").get_child(randi_range(0, get_node("/root/Map/Spawns").get_child_count() - 1)).global_position
	health = 32
	shield = 0
	
	ammo_light = 24
	ammo_medium = 32
	ammo_heavy = 8
	
	for child in hand.get_children():
		child.reset()
	is_dead = false

@rpc("any_peer")
func got_kill():
	if is_multiplayer_authority():
		Network.kills += 1

@rpc("call_local")
func change_item(old_node, new_node):
	if old_node and hand.get_node(old_node):
		hand.get_node(old_node).on_unequip()
	if new_node and hand.get_node(new_node):
		hand.get_node(new_node).on_equip()

@rpc("any_peer", "call_local")
func hurt(amount):
	hurt_sound.play()
	
	if not is_multiplayer_authority(): return
	
	var new_recent_damager = Peers.get_node(str(multiplayer.get_remote_sender_id()))
	if new_recent_damager and new_recent_damager != self:
		recent_damager = new_recent_damager
	
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
	if not is_multiplayer_authority(): return
	if is_dead: return
	
	if ability_ultimate.ultimate_charge == false:
		ability_ultimate.ultimate_charge = true
		return true
	return false

func pickup_item(item_name):
	if is_dead: return false
	
	if item_name == item_primary.name:
		if item_primary.ammo_type == 0:
			ammo_light += item_primary.mag_size
		if item_primary.ammo_type == 1:
			ammo_medium += item_primary.mag_size
		if item_primary.ammo_type == 2:
			ammo_heavy += item_primary.mag_size
		return true
	
	if hand.get_node(item_name).two_handed == false:
		if str(item_primary.name) == "Fists":
			item_primary = hand.get_node(item_name)
			change_item.rpc(str(item.name), item_name)
			item = item_primary
			return true
		if str(item_secondary.name) == "Fists":
			item_secondary = hand.get_node(item_name)
			change_item.rpc(str(item.name), item_name)
			item = item_secondary
			return true
	else:
		if str(item_primary.name) == "Fists" and str(item_secondary.name) == "Fists":
			item_primary = hand.get_node(item_name)
			item_secondary = hand.get_node(item_name)
			change_item.rpc(str(item.name), item_name)
			item = item_primary
			return true
	
	return false

func pickup_loadout():
	if is_dead: return false
	
	var used = false
	var mouse_normal = (global_position - get_global_mouse_position()).normalized().limit_length(1)
	
	if hand.get_node(Network.item_primary).two_handed == false and hand.get_node(Network.item_secondary).two_handed == false:
		if str(item_secondary.name) != Network.item_secondary:
			if item_secondary.droppable:
				drop_item.rpc(global_position - mouse_normal * 24, str(item_secondary.name), str(name) + "_ItemPickup_" + str(randi_range(1000, 9999)))
			
			item_secondary = hand.get_node(Network.item_secondary)
			change_item.rpc(str(item.name), Network.item_secondary)
			item = item_secondary
			
			used = true
		
		if str(item_primary.name) != Network.item_primary:
			if item_primary.droppable:
				drop_item.rpc(global_position - mouse_normal * 24, str(item_primary.name), str(name) + "_ItemPickup_" + str(randi_range(1000, 9999)))
			
			item_primary = hand.get_node(Network.item_primary)
			change_item.rpc(str(item.name), Network.item_primary)
			item = item_primary
			
			used = true
	else:
		if str(item_primary.name) != Network.item_primary:
			if item_secondary.droppable:
				drop_item.rpc(global_position - mouse_normal * 24, str(item_secondary.name), str(name) + "_ItemPickup_" + str(randi_range(1000, 9999)))
			if item_primary.droppable:
				drop_item.rpc(global_position - mouse_normal * 24, str(item_primary.name), str(name) + "_ItemPickup_" + str(randi_range(1000, 9999)))
			
			if hand.get_node(Network.item_primary).two_handed:
				item_primary = hand.get_node(Network.item_primary)
				item_secondary = hand.get_node(Network.item_primary)
				change_item.rpc(str(item.name), Network.item_primary)
				item = item_primary
			else:
				item_primary = hand.get_node(Network.item_secondary)
				item_secondary = hand.get_node(Network.item_secondary)
				change_item.rpc(str(item.name), Network.item_secondary)
				item = item_secondary
			
			used = true
	
	return used

func update_scoreboard():
	for child in scoreboard.get_children():
		if not child.is_class("Timer"):
			child.free()
	
	var peers = []
	for child in Peers.get_children():
		if not child.is_class("MultiplayerSpawner"):
			peers.append(child)
	peers.sort_custom(func(a, b): return a.score > b.score)
	
	for team in Globals.teams:
		var new_item = scoreboard_item.instantiate()
		new_item.name = team["name"]
		scoreboard.add_child(new_item)

func _on_foot_body_entered(_area):
	on_climbable = true

func _on_foot_body_exited(_area):
	on_climbable = false

@rpc("call_local")
func play_jump_sound():
	jump_sound.play()

func _on_leave_pressed():
	Network.leave_server()
	
	for child in Temporary.get_children():
		child.queue_free()
	for child in Peers.get_children():
		child.queue_free()
	
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
