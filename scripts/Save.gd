extends Node

signal save_loaded

@export var data = {}

func _ready():
	get_tree().set_auto_accept_quit(false)

func _notification(notif):
	if notif == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

func quit():
	save_data()
	
	await get_tree().create_timer(0.5).timeout
	
	get_tree().quit()

func save_data():
	data["item_primary"] = Network.item_primary
	data["item_secondary"] = Network.item_secondary
	data["ability_passive"] = Network.ability_passive
	data["ability_active1"] = Network.ability_active1
	data["ability_active2"] = Network.ability_active2
	data["ability_ultimate"] = Network.ability_ultimate
	
	save_binary()
	
	Logger.log_simple("SAVE", "Data saved")

func load_data():
	load_binary()
	
	Network.item_primary = data["item_primary"]
	Network.item_secondary = data["item_secondary"]
	Network.ability_passive = data["ability_passive"]
	Network.ability_active1 = data["ability_active1"]
	Network.ability_active2 = data["ability_active2"]
	Network.ability_ultimate = data["ability_ultimate"]
	
	save_loaded.emit()
	
	Logger.log_simple("SAVE", "Data loaded")

func clear_data():
	data["item_primary"] = "AK-47"
	data["item_secondary"] = "MP5"
	data["ability_passive"] = "Speedy"
	data["ability_active1"] = "Swarm"
	data["ability_active2"] = "Dash"
	data["ability_ultimate"] = "Firestorm"
	
	save_binary()
	
	Logger.log_simple("SAVE", "Data cleared")
	
	Save.load_data()

func save_binary():
	var file = FileAccess.open_encrypted_with_pass("user://save.dat", FileAccess.WRITE, "CatCombat")
	file.store_var(data)
	file.close()

func load_binary():
	if not FileAccess.file_exists("user://save.dat"):
		Logger.log_simple("SAVE", "No save file")
		save_data()
	var file = FileAccess.open_encrypted_with_pass("user://save.dat", FileAccess.READ, "CatCombat")
	data = file.get_var()
	file.close()
