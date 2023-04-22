extends Node

@export var port = 7777
@export var player = preload("res://scenes/Player.tscn")
@export var scoreboard_item = preload("res://scenes/ScoreboardItem.tscn")

signal on_start_game
@export var game_started = false
@export var time_till_start = -1

var address = ""

var username = "Username"
var item_primary = "AK-47"
var item_secondary = "MP5"
var ability_passive = "Speedy"
var ability_active1 = "Swarm"
var ability_active2 = "Dash"
var ability_ultimate = "Firestorm"

var score = 0
var kills = 0
var deaths = 0

var enet_peer = ENetMultiplayerPeer.new()

@onready var server_ui = $CanvasLayer/ServerUI
@onready var start_game_button = $CanvasLayer/ServerUI/StartGame
@onready var start_countdown = $CanvasLayer/ServerUI/StartCountdown

func set_username(new):
	username = new

func set_server_address(new):
	address = new

func join_server():
	Logger.log_simple("NETW", "Joining server...")
	
	enet_peer.create_client(address, port)
	multiplayer.multiplayer_peer = enet_peer
	
	PhysicsServer2D.set_active(false)
	
	Logger.log_simple("NETW", "Server joined")

func host_server():
	Logger.log_simple("NETW", "Server creating...")
	
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	# add_player(multiplayer.get_unique_id())
	
	server_ui.visible = true
	
	PhysicsServer2D.set_active(false)
	
	Logger.log_simple("NETW", "Server created")

func leave_server():
	multiplayer.set_multiplayer_peer(null)
	enet_peer = null
	
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(remove_player)
	
	PhysicsServer2D.set_active(true)
	
	Logger.log_simple("NETW", "Left server")

@rpc("call_local")
func start_game():
	PhysicsServer2D.set_active(true)
	
	game_started = true
	on_start_game.emit()

func add_player(peer_id):
	Logger.log_complex("NETW", "New connection", [
		["Peer ID", str(peer_id)],
		["Connection IP address", enet_peer.get_peer(peer_id).get_remote_address()],
		["Connection port", str(enet_peer.get_peer(peer_id).get_remote_port())]
	])
	
	if not game_started:
		await get_tree().create_timer(1).timeout
		
		var new_player = player.instantiate()
		new_player.name = str(peer_id)
		Peers.add_child(new_player)
	else:
		enet_peer.get_peer(peer_id).peer_disconnect_now()
		
		Logger.log_simple("NETW", "Peer[%s] was kicked, game started" % peer_id)

func remove_player(peer_id):
	Logger.log_complex("NETW", "Connection lost", [
		"Peer ID", str(peer_id),
		"Connection IP address", enet_peer.get_peer(peer_id).get_remote_address(),
		"Connection port", str(enet_peer.get_peer(peer_id).get_remote_port())
	])
	
	var old_player = Peers.get_node_or_null(str(peer_id))
	if old_player:
		old_player.dormant = true
		
		await get_tree().create_timer(1).timeout
		
		old_player.queue_free()

func _on_start_game_pressed():
	start_game_button.visible = false
	start_countdown.visible = true
	
	time_till_start = 10
	while time_till_start > 0:
		await get_tree().create_timer(1).timeout
		time_till_start -= 1
		start_countdown.text = str(time_till_start)
	
	start_game.rpc()
	
	start_countdown.visible = false

func _on_instant_start_game_pressed():
	start_game_button.visible = false
	start_countdown.visible = false
	
	time_till_start = 0
	start_game.rpc()
