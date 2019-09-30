extends Node

onready var box = $Box
onready var goal = $Goal
onready var endTimer = $Timer

var onGoal = false

signal simulationEnd

func _ready():
	goal.connect("body_entered", self, "_on_goal_entered")
	goal.connect("body_exited", self, "_on_goal_exited")
	box.goal = goal

func get_variables():
	var variables 
	variables.append(box)
	
func start_simulation():
	box.start()

func _on_goal_entered():
	onGoal = true

func _on_goal_exited():
	onGoal = false

func _on_Timer_timeout():
	emit_signal("simulationEnd", onGoal)
