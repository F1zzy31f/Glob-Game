extends CharacterBody2D

@export var initialized = false

@export var speed = 96
@export var jump_height = 48
@export var climb_speed = 128
@export var health = 16
@export var team_index = -1

@export var knockback_delay = 1
@export var knockback = Vector2(512, 128)
@export var damage = 4

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $Sprite
@onready var hurt_sound = $HurtSound

var on_climbable = false

var target = null
var knockback_timer = 0

class input:
	var jump = false
	var move_left = 0
	var move_right = 0
var ai_input = input.new()

func _enter_tree():
	set_multiplayer_authority(int(name.split("_")[0]), true)

@rpc("any_peer", "call_local")
func initialize(spawn_position):
	if not is_multiplayer_authority(): return
	
	initialized = true
	
	global_position = spawn_position

func _process(delta):
	if not is_multiplayer_authority() or not initialized: return
	
	knockback_timer += delta
	
	if target == null:
		for child in Peers.get_children():
			if child.is_class("CharacterBody2D") and child.name != str(get_multiplayer_authority()):
				target = child
		return
	
	var target_vector = global_position - target.global_position
	
	if target_vector.x > 24:
		ai_input.move_left = 1
		ai_input.move_right = 0
	elif target_vector.x < -24:
		ai_input.move_left = 0
		ai_input.move_right = 1
	else:
		ai_input.move_left = 0
		ai_input.move_right = 0
		
		if target_vector.length() < 36 and knockback_timer > knockback_delay:
			knockback_timer = 0
			
			target.knockback.rpc(Vector2(-knockback.x, -knockback.y) if target_vector.x > 0 else Vector2(knockback.x, -knockback.y))
			target.hurt.rpc(damage)
	
	if target_vector.y > 16:
		ai_input.jump = true
	else:
		ai_input.jump = false

func _physics_process(delta):
	if not is_multiplayer_authority() or not initialized: return
	
	# Dying
	if health <= 0 or global_position.y > 64:
		destroy.rpc()
		return
	
	# Movement
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if ai_input.jump and on_climbable:
		velocity.y = -climb_speed
	elif ai_input.jump and is_on_floor():
			velocity.y = -sqrt(jump_height * 2 * gravity)
	
	var direction = -ai_input.move_left + ai_input.move_right
	if direction:
		velocity.x = direction * speed
		sprite.animation = "walk"
		sprite.flip_h = true if velocity.x > 0 else false
	else:
		sprite.animation = "idle"
		velocity.x = move_toward(velocity.x, 0, speed)
	
	move_and_slide()

@rpc("any_peer", "call_local")
func hurt(amount):
	hurt_sound.play()
	
	if not is_multiplayer_authority(): return
	
	health -= amount
	
@rpc("any_peer", "call_local")
func destroy():
	visible = false
	set_deferred("freeze", true)
	get_node("CollisionShape2D").set_deferred("disabled", true)
	
	await get_tree().create_timer(1).timeout
	
	queue_free()


func _on_foot_body_entered(_area):
	on_climbable = true

func _on_foot_body_exited(_area):
	on_climbable = false



