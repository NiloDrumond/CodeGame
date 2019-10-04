extends KinematicBody2D

var speed = 1.2 setget set_speed, get_speed
var goal
var direction
var moving = false

func _ready():
	pass

func _physics_process(delta):
	if moving:
		move_and_slide(direction * speed)

func start():
	direction = goal.position - position
	moving = true
	
func get_set_variables():
	var variables = {
		"speed": funcref(self, "set_speed"),
	}
	return variables

func get_get_variables():
	var variables = {
		"speed": funcref(self, "get_speed"),
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
	
func get_speed():
	return speed

func get_functions():
	var functions = {}
	return functions
	
func stop():
	moving = false