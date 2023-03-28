extends Node

@export var save = {}

func _ready():
	get_tree().set_auto_accept_quit(false)
	
	load_data()

func _notification(notification):
	if notification == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

func quit():
	save_data()
	
	await get_tree().create_timer(0.5).timeout
	
	get_tree().quit()

func save_data():
	save["username"] = Network.username
	save["ability_passive"] = Network.ability_passive
	save["ability_active1"] = Network.ability_active1
	save["ability_active2"] = Network.ability_active2
	save["ability_ultimate"] = Network.ability_ultimate
	save["score"] = Network.score
	save["kills"] = Network.kills
	save["deaths"] = Network.deaths
	
	save_binary()
	
	print("[SAVE] : Data saved")

func load_data():
	load_binary()
	
	Network.username = save["username"]
	Network.ability_passive = save["ability_passive"]
	Network.ability_active1 = save["ability_active1"]
	Network.ability_active2 = save["ability_active2"]
	Network.ability_ultimate = save["ability_ultimate"]
	Network.score = save["score"]
	Network.kills = save["kills"]
	Network.deaths = save["deaths"]
	
	print("[SAVE] : Data loaded")

func save_binary():
	var file = FileAccess.open_encrypted_with_pass("user://save.dat", FileAccess.WRITE, "CatCombat")
	file.store_var(save)
	file.close()

func load_binary():
	var file = FileAccess.open_encrypted_with_pass("user://save.dat", FileAccess.READ, "CatCombat")
	save = file.get_var()
	file.close()
