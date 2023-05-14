extends Node

var public_ip = ""

@onready var public_ip_request = $PublicIPRequest
@onready var heartbeat_request = $HeartbeatRequest

func _ready():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
	
	if arguments.has("server") and arguments["server"] == "true":
		public_ip_request.request("https://api.ipify.org")

func heartbeat():
	if Network.game_started: return
	if Peers.get_child_count() - 1 >= Network.capacity: return
	
	heartbeat_request.request("http://" + Globals.discovery_server_ip + ":7770/?key=alex", [], HTTPClient.METHOD_POST, JSON.stringify({
		"name": "Server" + str(randi_range(100, 999)),
		"host": public_ip,
		"port": Network.port,
		"players": Peers.get_child_count() - 1,
		"capacity": Network.capacity
	}))

func _on_public_ip_request_request_completed(result, response_code, headers, body):
	public_ip = body.get_string_from_utf8()
	Logger.log_simple("HRTB", "Got public ip, %s" % public_ip)
	
	heartbeat()

func _on_heartbeat_request_request_completed(result, response_code, headers, body):
	Logger.log_simple("HRTB", "Completed heartbeat")
	await get_tree().create_timer(5).timeout
	heartbeat()
