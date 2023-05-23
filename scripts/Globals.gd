extends Node

var discovery_server_ip = "93.89.131.224"

var teams = [
	{"name": "The Blue Bloods", "color": Color.MEDIUM_SEA_GREEN},
	{"name": "The Oracles", "color": Color.CORNFLOWER_BLUE},
	{"name": "The Beast Lords", "color": Color.HOT_PINK},
	{"name": "The Midas Magi", "color": Color.ORANGE},
	{"name": "The Technomancers", "color": Color.PALE_GOLDENROD},
]
enum dimension { Material, Mirror, UrMom }

var arguments = {}

func _enter_tree():
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
