extends Sprite2D
class_name Item

@export var speed_multiplier = 1.0

var is_equip = false

func reset():
	print("Item reset not implemented")

func on_equip():
	print("Item equip not implemented")

func on_unequip():
	print("Item unequip not implemented")

func get_item_info():
	print("Item get info not implemented")
	return "Not implemented"
