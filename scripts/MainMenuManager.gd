extends Control

@onready var menus = $Menus
@onready var ability_passive = $Menus/CustomizeMenu/Content/AbilityPassive/Dropdown
@onready var ability_active_1 = $Menus/CustomizeMenu/Content/AbilityActive1/Dropdown
@onready var ability_active_2 = $Menus/CustomizeMenu/Content/AbilityActive2/Dropdown
@onready var ability_ultimate = $Menus/CustomizeMenu/Content/AbilityUltimate/Dropdown

var menu_queue = ["TitleMenu"]

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

func _on_settings_pressed():
	open_menu("SettingsMenu")

func _on_quit_pressed():
	get_tree().quit()

func _on_customize_pressed():
	open_menu("CustomizeMenu")

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
	Network.ability_active1 = ability_active_1.get_item_text(index)

func _on_ability_active_2_item_selected(index):
	Network.ability_active2 = ability_active_2.get_item_text(index)

func _on_ability_ultimate_item_selected(index):
	Network.ability_ultimate = ability_ultimate.get_item_text(index)
