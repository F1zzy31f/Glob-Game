extends Item

func _ready():
	reset()

func reset():
	pass

func on_equip():
	is_equip = true

func on_unequip():
	is_equip = false

func get_item_info():
	return "Fists"
