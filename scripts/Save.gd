extends Node

signal save_loaded

@export var data = {}

func _ready():
	get_tree().set_auto_accept_quit(false)

func _notification(notif):
	if notif == NOTIFICATION_WM_CLOSE_REQUEST:
		quit()

func quit():
	await save_data()
	
	get_tree().quit()

func save_data():
	data["item_primary"] = Network.item_primary
	data["item_secondary"] = Network.item_secondary
	data["ability_passive"] = Network.ability_passive
	data["ability_active1"] = Network.ability_active1
	data["ability_active2"] = Network.ability_active2
	data["ability_ultimate"] = Network.ability_ultimate
	
	await save_firebase()
	
	Logger.log_simple("SAVE", "Data saved")

func load_data():
	await load_firebase()
	
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
	
	await save_firebase()
	
	Logger.log_simple("SAVE", "Data cleared")

func save_firebase():
	Firebase.Auth.get_user_data()
	var user_data = await Firebase.Auth.userdata_received
	
	var accounts_collection = Firebase.Firestore.collection("accounts")
	accounts_collection.update(user_data["local_id"], {
		"item_primary": Network.item_primary,
		"item_secondary": Network.item_secondary,
		"ability_passive": Network.ability_passive,
		"ability_active1": Network.ability_active1,
		"ability_active2": Network.ability_active2,
		"ability_ultimate": Network.ability_ultimate
	})
	await accounts_collection.update_document

func load_firebase():
	Firebase.Auth.get_user_data()
	var user_data = await Firebase.Auth.userdata_received
	
	var accounts_collection = Firebase.Firestore.collection("accounts")
	accounts_collection.get_doc(user_data["local_id"])
	var document = await accounts_collection.get_document
	
	if not document["doc_fields"].has("item_primary"):
		await clear_data()
	else:
		data = document["doc_fields"]
