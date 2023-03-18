extends Node

@export var port = 7777
@export var player = preload("res://scenes/Player.tscn")
@export var scoreboard_item = preload("res://scenes/ScoreboardItem.tscn")

@onready var join_ui = $CanvasLayer/JoinUI
@onready var address_ui = $CanvasLayer/Address

var address = ""

var enet_peer = ENetMultiplayerPeer.new()

func _ready():
	address_ui.visible = false
	address_ui.text = IP.get_local_addresses()[3]

func _on_server_address_text_changed(new_text):
	address = new_text

func _on_join_server_pressed():
	join_ui.visible = false
	
	enet_peer.create_client(address, port)
	multiplayer.multiplayer_peer = enet_peer

func _on_host_server_pressed():
	join_ui.visible = false
	address_ui.visible = true
	
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())

func add_player(peer_id):
	# Player
	var new_player = player.instantiate()
	new_player.name = str(peer_id)
	Peers.add_child(new_player)

func remove_player(peer_id):
	# Player
	var old_player = Peers.get_node_or_null(str(peer_id))
	if old_player:
		old_player.queue_free()
