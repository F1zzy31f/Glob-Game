extends Node

signal save_loaded

@export var data = {}

func _ready():
	print(get_property_list())
	
	get_tree().set_auto_accept_quit(false)
	
	await get_tree().create_timer(0.5).timeout
	
	load_data()

func _notification(notification):
	if notification == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

func quit():
	save_data()
	
	await get_tree().create_timer(0.5).timeout
	
	get_tree().quit()

func save_data():
	data["username"] = Network.username
	data["ability_passive"] = Network.ability_passive
	data["ability_active1"] = Network.ability_active1
	data["ability_active2"] = Network.ability_active2
	data["ability_ultimate"] = Network.ability_ultimate
	data["score"] = Network.score
	data["kills"] = Network.kills
	data["deaths"] = Network.deaths
	
	save_binary()
	
	print("[SAVE] : Data saved")

func load_data():
	load_binary()
	
	Network.username = data["username"]
	Network.ability_passive = data["ability_passive"]
	Network.ability_active1 = data["ability_active1"]
	Network.ability_active2 = data["ability_active2"]
	Network.ability_ultimate = data["ability_ultimate"]
	Network.score = data["score"]
	Network.kills = data["kills"]
	Network.deaths = data["deaths"]
	
	save_loaded.emit()
	
	print("[SAVE] : Data loaded")

func save_binary():
	var file = FileAccess.open_encrypted_with_pass("user://save.dat", FileAccess.WRITE, "CatCombat")
	file.store_var(data)
	file.close()

func load_binary():
	if not FileAccess.file_exists("user://save.dat"):
		print("[SAVE] : No save file")
		save_data()
	var file = FileAccess.open_encrypted_with_pass("user://save.dat", FileAccess.READ, "CatCombat")
	data = file.get_var()
	file.close()
