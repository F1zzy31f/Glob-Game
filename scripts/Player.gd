extends CharacterBody2D

@export var speed = 128
@export var jump_height = 48
@export var health = 0
@export var item_index = 0
@export var team_index = 0 # 1-16 (0-15)
@export var ambient_healing_timer = 0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $Sprite
@onready var team_indicator = $TeamIndicator
@onready var camera = $Camera
@onready var audio_listener = $Camera/AudioListener
@onready var hand_pivot = $HandPivot
@onready var hand = $HandPivot/Hand
@onready var ui = $CanvasLayer/UI
@onready var healthbar_inner = $CanvasLayer/UI/Healthbar
@onready var hurt_sound = $HurtSound

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	change_item(item_index, item_index)
	
	if not is_multiplayer_authority(): return
	
	ui.visible = true
	camera.enabled = true
	audio_listener.make_current()
	
	team_index = randi_range(0, 15)

func _process(delta):
	if not is_multiplayer_authority(): return
	
	# UI
	healthbar_inner.value = health
	
	$CanvasLayer/UI/TeamIndex.text = "Team: " + str(team_index + 1)
	team_indicator.modulate = Color.from_hsv(team_index / float(16), 1, 1)
	
	# Update
	ambient_healing_timer += delta
	
	if ambient_healing_timer > 3:
		health += (delta * 16) / 32
	health = clamp(health, 0, 16)

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Dying
	if health <= 0 or global_position.y > 64:
		global_position = get_node("/root/Main/Spawns").get_child(randi_range(0, get_node("/root/Main/Spawns").get_child_count() - 1)).global_position
		health = 16
	
	# Movement
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -sqrt(jump_height * 2 * gravity)
	
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
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

@rpc
func change_item(old_index, new_index):
	hand.get_child(old_index).on_unequip()
	hand.get_child(new_index).on_equip()

@rpc("any_peer", "call_local")
func hurt(amount):
	hurt_sound.play()
	
	if not is_multiplayer_authority(): return
	
	health -= amount
	ambient_healing_timer = 0

func _on_team_up_pressed():
	team_index = clamp(team_index + 1, 0, 15)
	$CanvasLayer/UI/TeamUp.release_focus()

func _on_team_down_pressed():
	team_index = clamp(team_index - 1, 0, 15)
	$CanvasLayer/UI/TeamDown.release_focus()
