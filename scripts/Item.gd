extends Sprite2D
class_name Item

@export var droppable = true
@export var two_handed = false
@export var speed_multiplier = 1.0

var is_equip = false

func reset():
	Logger.log_simple("ITEM", "Item reset not implemented")

func on_equip():
	Logger.log_simple("ITEM", "Item equip not implemented")

func on_unequip():
	Logger.log_simple("ITEM", "Item unequip not implemented")

func get_item_info():
	Logger.log_simple("ITEM", "Item get info not implemented")
	return "Not implemented"
