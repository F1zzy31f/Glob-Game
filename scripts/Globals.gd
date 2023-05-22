extends Node

var discovery_server_ip = "93.89.131.224"

var teams = [
	{"name": "1", "color": Color.MEDIUM_SEA_GREEN},
	{"name": "2", "color": Color.CORNFLOWER_BLUE},
	{"name": "3", "color": Color.HOT_PINK},
	{"name": "4", "color": Color.ORANGE},
	{"name": "5", "color": Color.PALE_GOLDENROD},
]
enum dimension { Material, Mirror, UrMom }

var arguments = {}

func _enter_tree():
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
