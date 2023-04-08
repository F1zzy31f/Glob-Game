extends Node

@export var port = 7777
@export var player = preload("res://scenes/Player.tscn")
@export var scoreboard_item = preload("res://scenes/ScoreboardItem.tscn")

signal on_start_game
@export var game_started = false
@export var time_till_start = 15

var address = ""

var username = "Username"
var item_primary = "AK-47"
var item_secondary = "MP5"
var ability_passive = "Fast Feet"
var ability_active1 = "Fireball"
var ability_active2 = "Stimulant"
var ability_ultimate = "Firestorm"

var score = 0
var kills = 0
var deaths = 0

var enet_peer = ENetMultiplayerPeer.new()

func set_username(new):
	username = new

func set_server_address(new):
	address = new

func join_server():
	enet_peer.create_client(address, port)
	multiplayer.multiplayer_peer = enet_peer

func host_server():
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	# add_player(multiplayer.get_unique_id())
	
	while time_till_start > 0:
		await get_tree().create_timer(1).timeout
		time_till_start -= 1
	
	start_game.rpc()

func leave_server():
	multiplayer.set_multiplayer_peer(null)
	enet_peer = null
	
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(remove_player)

@rpc("call_local")
func start_game():
	game_started = true
	on_start_game.emit()

func add_player(peer_id):
	if not game_started:
		await get_tree().create_timer(1).timeout
		
		var new_player = player.instantiate()
		new_player.name = str(peer_id)
		Peers.add_child(new_player)
	else:
		enet_peer.get_peer(peer_id).peer_disconnect_now()

func remove_player(peer_id):
	var old_player = Peers.get_node_or_null(str(peer_id))
	if old_player:
		old_player.dormant = true
		
		await get_tree().create_timer(1).timeout
		
		old_player.queue_free()
