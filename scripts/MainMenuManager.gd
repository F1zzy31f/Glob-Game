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
@onready var globapedia_image = $Menus/GlobapediaMenu/Content/Info/Image
@onready var globapedia_title = $Menus/GlobapediaMenu/Content/Info/Title
@onready var globapedia_type = $Menus/GlobapediaMenu/Content/Info/Type
@onready var globapedia_description = $Menus/GlobapediaMenu/Content/Info/DescriptionContainer/Description
@onready var direct_address = $Menus/DirectConnectMenu/Content/Address
@onready var direct_port = $Menus/DirectConnectMenu/Content/Port

var menu_queue = []

var servers = []

func _ready():
	Save.save_loaded.connect(self.save_loaded)
	Save.load_data()
	
	get_server_list()
	
	if Globals.arguments.has("port"):
		Network.port = int(Globals.arguments["port"])
	if Globals.arguments.has("server"):
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
	open_menu("LoadingMenu")
	
	await get_tree().create_timer(0.1).timeout
	
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

func _on_get_server_list_request_request_completed(_result, _response_code, _headers, body):
	servers = JSON.parse_string(body.get_string_from_utf8())
	
	if servers:
		for child in server_list.get_children():
			child.queue_free()
		for server in servers:
			var new_listing = server_listing.instantiate()
			new_listing.name = server["host"]
			server_list.add_child(new_listing)
			new_listing.get_child(1).text = server["name"]
			new_listing.get_child(2).text = str(server["players"]) + " / " + str(server["capacity"])
			new_listing.get_child(3).pressed.connect(func():
				_on_join_game_pressed(server["host"], int(server["port"]))
			)
	
	await get_tree().create_timer(5).timeout
	get_server_list()


func _on_direct_connect_pressed():
	open_menu("DirectConnectMenu")

func _on_connect_pressed():
	_on_join_game_pressed(direct_address.text, int(direct_port.text))

func _on_globapedia_pressed():
	open_menu("GlobapediaMenu")

func _on_globapedia_text_changed(new_text):
	var result = {
		"image_src": "res://assets/images/globapedia/na.png",
		"title": "Nothing Found",
		"type": "N / A",
		"description": "There was nothing found so how could there be a description"
	}
	
	for glob in Globapedia.globapedia:
		for glob_name in glob["names"]:
			if glob_name == new_text.to_lower():
				result = glob
	
	globapedia_image.texture = load(result["image_src"])
	globapedia_title.text = result["title"]
	globapedia_type.text = result["type"]
	globapedia_description.text = result["description"]
