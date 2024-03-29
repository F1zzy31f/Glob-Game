extends Node

var public_ip = ""

@onready var public_ip_request = $PublicIPRequest
@onready var heartbeat_request = $HeartbeatRequest

func _ready():
	if Globals.arguments.has("server"):
		public_ip_request.request("https://api64.ipify.org")

func heartbeat():
	if Network.game_started: return
	if Peers.get_child_count() - 1 >= Network.capacity: return
	
	heartbeat_request.request("http://" + Globals.discovery_server_ip + ":7770/?key=alex", [], HTTPClient.METHOD_POST, JSON.stringify({
		"name": Globals.arguments["server"],
		"host": public_ip,
		"port": Network.port,
		"players": Peers.get_child_count() - 1,
		"capacity": Network.capacity
	}))

func _on_public_ip_request_request_completed(_result, _response_code, _headers, body):
	public_ip = body.get_string_from_utf8()
	Logger.log_simple("HRTB", "Got public ip, %s" % public_ip)
	
	heartbeat()

func _on_heartbeat_request_request_completed(_result, _response_code, _headers, _body):
	Logger.log_simple("HRTB", "Completed heartbeat")
	await get_tree().create_timer(5).timeout
	heartbeat()
