extends KinematicBody2D

var speed = 1.2 
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
	
func get_variables():
	var variables = {
		"speed": true,
		"position": false
	}
	return variables
	



func get_functions():
	var functions = {}
	return functions
	
func stop():
	moving = false