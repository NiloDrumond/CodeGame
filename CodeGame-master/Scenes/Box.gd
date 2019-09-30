extends KinematicBody2D

var speed = 1.2 setget set_speed
var goal
var direction
var moving = false

func _ready():
	pass

func _physics_process(delta):
	if moving:
		move_and_slide(direction * speed)
	
func set_speed(value):
	speed = value
	
func start():
	direction = goal.position - position
	moving = true