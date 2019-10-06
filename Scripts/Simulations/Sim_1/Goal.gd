extends Area2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_set_variables():
	var variables = {}
	return variables

func get_get_variables():
	var variables = {
		"positionX": funcref(self, "get_positionX"),
		"positionY": funcref(self, "get_positionY")
	}
	return variables
	
func get_positionX():
	return position.x

func get_positionY():
	return position.y
	
func get_functions():
	var functions = {}
	return functions