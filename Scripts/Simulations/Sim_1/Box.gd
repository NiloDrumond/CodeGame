extends KinematicBody2D

var speed = Vector2(0, 0) setget set_speed
var goal
var moving = false

func _ready():
	pass

func _physics_process(delta):
	if moving:
		move_and_slide(speed)

func start():
	moving = true
	
func get_set_variables():
	var variables = {
		"speedVector": funcref(self, "set_speed"),
	}
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

func set_speed(value):
	speed = value
	

func get_functions():
	var functions = {}
	return functions
	
func stop():
	moving = false