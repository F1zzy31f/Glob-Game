extends CharacterBody2D

@export var dormant = false
@export var username = ""

@export var speed = 96
@export var jump_height = 48
@export var climb_speed = 128
@export var health = 0
@export var item_index = 0
@export var team_index = 0 # 1-16 (0-15)
@export var ambient_healing_timer = 0
@export var scoreboard_item = preload("res://scenes/ScoreboardItem.tscn")
@export var inventory_item = preload("res://scenes/InventoryItem.tscn")

@export var score = 0
@export var kills = 0
@export var deaths = -1

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
@onready var healthbar_inner = $CanvasLayer/UI/Healthbar
@onready var item_info = $CanvasLayer/UI/ItemInfo
@onready var inventory = $CanvasLayer/UI/Inventory
@onready var ability_ui_active1 = $CanvasLayer/UI/Abilities/Active1
@onready var ability_ui_active2 = $CanvasLayer/UI/Abilities/Active2
@onready var ability_ui_ultimate = $CanvasLayer/UI/Abilities/Ultimate
@onready var scoreboard = $CanvasLayer/UI/Scoreboard
@onready var hurt_sound = $HurtSound

var ability_passive = null
var ability_active1 = null
var ability_active2 = null
var ability_ultimate = null

var is_dead = false
var on_climbable = false
var recent_damager = null

func _enter_tree():
	set_multiplayer_authority(str(name).to_int(), true)

func _ready():
	change_item(item_index, item_index)
	
	if not is_multiplayer_authority(): return
	
	username = Network.username
	overhead_username.text = username
	
	team_index = randi_range(0, Globals.team_count - 1)
	
	ability_passive = passive_abilities.get_child(randi_range(0, passive_abilities.get_child_count() - 1))
	ability_active1 = active_abilities.get_child(randi_range(0, active_abilities.get_child_count() - 1))
	ability_active2 = active_abilities.get_child(randi_range(0, active_abilities.get_child_count() - 1))
	ability_ultimate = ultimate_abilities.get_child(randi_range(0, ultimate_abilities.get_child_count() - 1))
	
	ui.visible = true
	camera.enabled = true
	audio_listener.make_current()

func _process(delta):
	if not is_multiplayer_authority(): return
	
	# UI
	healthbar_inner.value = health
	
	$CanvasLayer/UI/TeamIndex.text = "Team: " + str(team_index + 1)
	
	item_info.text = hand.get_child(item_index).get_item_info()
	for child in inventory.get_children():
		child.free()
	for child in hand.get_children():
		var new_item = inventory_item.instantiate()
		new_item.name = child.name
		new_item.get_child(0).text = str(new_item.name)
		new_item.self_modulate = Color.from_hsv(0, 0, 0.4) if child.is_equip else Color.from_hsv(0, 0, 0.3)
		inventory.add_child(new_item)
	
	ability_ui_active1.get_child(0).text = ability_active1.name
	ability_ui_active1.get_child(1).value =ability_active1.recharge_timer
	ability_ui_active1.get_child(1).max_value = ability_active1.active_recharge
	
	ability_ui_active2.get_child(0).text = ability_active2.name
	ability_ui_active2.get_child(1).value = ability_active2.recharge_timer
	ability_ui_active2.get_child(1).max_value = ability_active2.active_recharge
	
	ability_ui_ultimate.get_child(0).text = ability_ultimate.name
	ability_ui_ultimate.get_child(1).value = 1 if ability_ultimate.ultimate_charge else 0
	
	# Update
	ambient_healing_timer += delta
	
	if ambient_healing_timer > 3:
		health += (delta * 32) / 32 # x / Time to heal
	health = clamp(health, 0, 32)
	
	# Abilities
	if Input.is_action_just_pressed("ability_active_1"):
		ability_active1.activate()
	if Input.is_action_just_pressed("ability_active_2"):
		ability_active2.activate()
	if Input.is_action_just_pressed("ability_ultimate"):
		ability_ultimate.activate()
	
	# Score
	score = kills - deaths

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Dying
	if health <= 0 or global_position.y > 64 and not is_dead:
		on_die()
	
	# Movement
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_pressed("jump") and on_climbable:
		velocity.y = -climb_speed
	elif Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = -sqrt(jump_height * 2 * gravity)
	
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * (speed * hand.get_child(item_index).speed_multiplier)
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
	var old_item_index = item_index
	if Input.is_action_just_pressed("item_up"):
		item_index += 1
	if Input.is_action_just_pressed("item_down"):
		item_index -= 1
	if item_index > hand.get_child_count() - 1:
		item_index = 0
	if item_index < 0:
		item_index = hand.get_child_count() - 1
	if item_index != old_item_index:
		change_item(old_item_index, item_index)
		change_item.rpc(old_item_index, item_index)

func on_die():
	is_dead = true
	var damager = Peers.get_node_or_null(str(recent_damager))
	if damager:
		damager.got_kill.rpc()
	
	deaths += 1
	
	global_position = get_node("/root/Map/Spawns").get_child(randi_range(0, get_node("/root/Map/Spawns").get_child_count() - 1)).global_position
	health = 32
	
	for child in hand.get_children():
		child.reset()
	is_dead = false

@rpc("any_peer")
func got_kill():
	kills += 1

@rpc
func change_item(old_index, new_index):
	hand.get_child(old_index).on_unequip()
	hand.get_child(new_index).on_equip()

@rpc("any_peer", "call_local")
func hurt(amount):
	hurt_sound.play()
	
	if not is_multiplayer_authority(): return
	
	recent_damager = multiplayer.get_remote_sender_id()
	
	health -= amount
	ambient_healing_timer = 0

@rpc("any_peer", "call_local")
func knockback(vector):
	velocity += vector

func charge_ultimate():
	if not is_multiplayer_authority(): return
	
	if ability_ultimate.ultimate_charge == false:
		ability_ultimate.ultimate_charge = true
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
