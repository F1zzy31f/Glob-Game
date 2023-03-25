extends Node2D

@export var scoreboard_item = preload("res://scenes/ScoreboardItem.tscn")

@export var dormant = false
@export var username = ""
@export var team_index = 0

@export var score = 0
@export var kills = 0
@export var deaths = -1

@export var player_controller = preload("res://scenes/PlayerController.tscn")

@onready var ui = $CanvasLayer/UI
@onready var scoreboard = $CanvasLayer/UI/Scoreboard

var controller = null
var spawning_controller = false

func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	if not is_multiplayer_authority(): return
	
	username = Network.username
	ui.visible = true

func _process(delta):
	if not is_multiplayer_authority(): return
	
	if controller == null and not spawning_controller:
		spawning_controller = true
		await get_tree().create_timer(1).timeout
		spawn_controller()
		spawning_controller = false

func spawn_controller():
	controller = player_controller.instantiate()
	controller.name = name + "_Controller"
	Temporary.add_child(controller)

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

@rpc("any_peer", "call_local")
func on_kill():
	kills += 1

@rpc("any_peer", "call_local")
func on_death():
	deaths += 1
