extends Node

func log_simple(system, title):
	var output = get_time_formatted() + " | "
	output += "[%s] : " % system
	output += title
	
	print(output)

func log_complex(system, title, details):
	var output = get_time_formatted() + " | "
	output += "[%s] : " % system
	output += title
	
	print(output)
	
	for detail in details:
		output = " -> "
		output += "[%s] - " % detail[0]
		output += detail[1]
		
		print(output)

func get_time_formatted():
	var time = Time.get_time_dict_from_system()
	return "%02d:%02d:%02d" % [time.hour, time.minute, time.second]
