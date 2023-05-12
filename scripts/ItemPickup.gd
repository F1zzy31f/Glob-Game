extends RigidBody2D

@export var initialized = false
@export var item_name = "AK-47"

@onready var item_name_ui = $OverheadUI/ItemName

func _process(_delta):
	item_name_ui.text = item_name

@rpc("any_peer", "call_local")
func initialize(pickup_position, pickup_item_name):
	if not is_multiplayer_authority(): return
	
	initialized = true
	
	global_position = pickup_position
	item_name = pickup_item_name

func _on_detection_area_body_entered(body):
	if not initialized: return
	
	if body and body.is_in_group("Player"):
		if body.is_multiplayer_authority():
			if body.pickup_item(item_name):
				destroy.rpc()

@rpc("any_peer", "call_local")
func destroy():
	visible = false
	set_deferred("freeze", true)
	get_node("CollisionShape2D").set_deferred("disabled", true)
	
	await get_tree().create_timer(1).timeout
	
	queue_free()
