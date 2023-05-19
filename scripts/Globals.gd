extends Node

var discovery_server_ip = "93.89.131.224"

var team_count = 4
enum dimension { Material, Mirror, UrMom }

var arguments = {}

func _ready():
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
