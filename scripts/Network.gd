extends Node

@export var port = 7777
@export var player = preload("res://scenes/Player.tscn")
@export var scoreboard_item = preload("res://scenes/ScoreboardItem.tscn")

var address = ""

var username = "Username"
var ability_active_1 = "Fireball"
var ability_active_2 = "Fast"
var ability_ultimate = "Goblins"

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
	
	add_player(multiplayer.get_unique_id())

func add_player(peer_id):
	await get_tree().create_timer(1).timeout
	
	var new_player = player.instantiate()
	new_player.name = str(peer_id)
	Peers.add_child(new_player)

func remove_player(peer_id):
	var old_player = Peers.get_node_or_null(str(peer_id))
	if old_player:
		old_player.dormant = true
		
		await get_tree().create_timer(1).timeout
		
		old_player.queue_free()
