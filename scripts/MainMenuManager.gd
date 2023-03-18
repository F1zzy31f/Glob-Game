extends Control

@onready var menus = $Menus

func open_menu(menu_name):
	for child in menus.get_children():
		child.visible = child.name == menu_name

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
