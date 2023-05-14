extends Control

@export var server_listing = preload("res://scenes/ServerListing.tscn")

var has_save_loaded = false

@onready var menus = $Menus
@onready var get_server_list_request = $GetServerListRequest

@onready var server_list = $Menus/PlayMenu/Content/ServerList/Content
@onready var username = $Menus/TitleMenu/Content/Username
@onready var item_primary = $Menus/CustomizeMenu/Content/ItemPrimary/Dropdown
@onready var item_secondary = $Menus/CustomizeMenu/Content/ItemSecondary/Dropdown
@onready var ability_passive = $Menus/CustomizeMenu/Content/AbilityPassive/Dropdown
@onready var ability_active1 = $Menus/CustomizeMenu/Content/AbilityActive1/Dropdown
@onready var ability_active2 = $Menus/CustomizeMenu/Content/AbilityActive2/Dropdown
@onready var ability_ultimate = $Menus/CustomizeMenu/Content/AbilityUltimate/Dropdown

var menu_queue = []

var servers = []

func _ready():
	Save.save_loaded.connect(self.save_loaded)
	Save.load_data()
	
	get_server_list()
	
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
	
	if arguments.has("port"):
		Network.port = int(arguments["port"])
	if arguments.has("server") and arguments["server"] == "true":
		Network.start_on_join = true
		
		get_tree().change_scene_to_file("res://scenes/Map.tscn")
		Network.host_server()

func save_loaded():
	if has_save_loaded == false:
		has_save_loaded = true
		open_menu("TitleMenu")
	
	username.text = Save.data["username"]
	
	for item in item_primary.item_count:
		if item_primary.get_item_text(item) == Save.data["item_primary"]:
			item_primary.select(item)
	for item in item_secondary.item_count:
		if item_secondary.get_item_text(item) == Save.data["item_secondary"]:
			item_secondary.select(item)
	
	for item in ability_passive.item_count:
		if ability_passive.get_item_text(item) == Save.data["ability_passive"]:
			ability_passive.select(item)
	for item in ability_active1.item_count:
		if ability_active1.get_item_text(item) == Save.data["ability_active1"]:
			ability_active1.select(item)
	for item in ability_active2.item_count:
		if ability_active2.get_item_text(item) == Save.data["ability_active2"]:
			ability_active2.select(item)
	for item in ability_ultimate.item_count:
		if ability_ultimate.get_item_text(item) == Save.data["ability_ultimate"]:
			ability_ultimate.select(item)

func open_menu(menu_name):
	if menu_name == "Back":
		menu_queue.pop_back()
		menu_name = menu_queue.back()
	else:
		menu_queue.append(menu_name)
	
	for child in menus.get_children():
		child.visible = child.name == menu_name

func _on_username_text_changed(new_text):
	Network.set_username(new_text)

func _on_play_pressed():
	open_menu("PlayMenu")

func _on_customize_pressed():
	open_menu("CustomizeMenu")

func _on_settings_pressed():
	open_menu("SettingsMenu")

func _on_quit_pressed():
	Save.quit()

func _on_back_pressed():
	open_menu("Back")

func _on_join_game_pressed(host, port):
	get_tree().change_scene_to_file("res://scenes/Map.tscn")
	
	Network.address = host
	Network.port = port
	
	Network.join_server()

func _on_ip_address_text_changed(new_text):
	Network.set_server_address(new_text)

func _on_item_primary_item_selected(index):
	Network.item_primary = item_primary.get_item_text(index)

func _on_item_secondary_item_selected(index):
	Network.item_secondary = item_secondary.get_item_text(index)

func _on_ability_passive_item_selected(index):
	Network.ability_passive = ability_passive.get_item_text(index)

func _on_ability_active_1_item_selected(index):
	Network.ability_active1 = ability_active1.get_item_text(index)

func _on_ability_active_2_item_selected(index):
	Network.ability_active2 = ability_active2.get_item_text(index)

func _on_ability_ultimate_item_selected(index):
	Network.ability_ultimate = ability_ultimate.get_item_text(index)

func _on_clear_save_pressed():
	Save.clear_data()

func get_server_list():
	get_server_list_request.request("http://" + Globals.discovery_server_ip + ":7770", [], HTTPClient.METHOD_GET)

func _on_get_server_list_request_request_completed(result, response_code, headers, body):
	servers = JSON.parse_string(body.get_string_from_utf8())
	
	for child in server_list.get_children():
		child.queue_free()
	for server in servers:
		var new_listing = server_listing.instantiate()
		new_listing.name = server["host"]
		server_list.add_child(new_listing)
		new_listing.get_child(1).text = server["name"]
		new_listing.get_child(2).text = str(server["players"]) + " / " + str(server["capacity"])
		new_listing.get_child(3).pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/Map.tscn")
			Network.address = server["host"]
			Network.port = int(server["port"])
			Network.join_server()
		)
	
	await get_tree().create_timer(5).timeout
	get_server_list()
