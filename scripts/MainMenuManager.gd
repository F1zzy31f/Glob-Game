extends Control

@onready var menus = $Menus
@onready var ability_active_1 = $Menus/PlayMenu/Abilities/AbilityActive1/Dropdown
@onready var ability_active_2 = $Menus/PlayMenu/Abilities/AbilityActive2/Dropdown
@onready var ability_ultimate = $Menus/PlayMenu/Abilities/AbilityUltimate/Dropdown

func open_menu(menu_name):
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

func _on_back_pressed():
	open_menu("TitleMenu")

func _on_join_game_pressed():
	get_tree().change_scene_to_file("res://scenes/Map.tscn")
	
	Network.join_server()

func _on_host_game_pressed():
	get_tree().change_scene_to_file("res://scenes/Map.tscn")
	
	Network.host_server()

func _on_ip_address_text_changed(new_text):
	Network.set_server_address(new_text)

func _on_ability_active_1_item_selected(index):
	Network.ability_active_1 = ability_active_1.get_item_text(index)

func _on_ability_active_2_item_selected(index):
	Network.ability_active_2 = ability_active_2.get_item_text(index)

func _on_ability_ultimate_item_selected(index):
	Network.ability_ultimate = ability_ultimate.get_item_text(index)
