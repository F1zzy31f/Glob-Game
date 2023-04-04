extends Control

var has_save_loaded = false

@onready var menus = $Menus
@onready var username = $Menus/TitleMenu/Content/Username

@onready var ability_passive = $Menus/CustomizeMenu/Content/AbilityPassive/Dropdown
@onready var ability_active1 = $Menus/CustomizeMenu/Content/AbilityActive1/Dropdown
@onready var ability_active2 = $Menus/CustomizeMenu/Content/AbilityActive2/Dropdown
@onready var ability_ultimate = $Menus/CustomizeMenu/Content/AbilityUltimate/Dropdown

@onready var resolution = $Menus/SettingsMenu/Content/Resolution/Dropdown

var menu_queue = []

func _ready():
	Save.save_loaded.connect(self.save_loaded)
	Save.load_data()

func save_loaded():
	if has_save_loaded == false:
		has_save_loaded = true
		open_menu("TitleMenu")
	
	username.text = Save.data["username"]
	
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

func _on_join_game_pressed():
	get_tree().change_scene_to_file("res://scenes/Map.tscn")
	
	Network.join_server()

func _on_host_game_pressed():
	get_tree().change_scene_to_file("res://scenes/Map.tscn")
	
	Network.host_server()

func _on_ip_address_text_changed(new_text):
	Network.set_server_address(new_text)

func _on_ability_passive_item_selected(index):
	Network.ability_passive = ability_passive.get_item_text(index)

func _on_ability_active_1_item_selected(index):
	Network.ability_active1 = ability_active1.get_item_text(index)

func _on_ability_active_2_item_selected(index):
	Network.ability_active2 = ability_active2.get_item_text(index)

func _on_ability_ultimate_item_selected(index):
	Network.ability_ultimate = ability_ultimate.get_item_text(index)

func _on_resolution_item_selected(index):
	var resolution_text = resolution.get_item_text(index)
	resolution_text = resolution_text.split("x")
	resolution_text = Vector2(int(resolution_text[0]), int(resolution_text[1]))
	
	DisplayServer.window_set_size(resolution_text)

func _on_clear_save_pressed():
	Save.clear_data()
