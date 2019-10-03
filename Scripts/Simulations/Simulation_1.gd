extends Node

onready var box = $Box
onready var goal = $Goal
onready var endTimer = $Timer

export(int) var duration = 2
var onGoal = false

signal simulationEnd

func _ready():
	goal.connect("body_entered", self, "_on_goal_entered")
	goal.connect("body_exited", self, "_on_goal_exited")
	box.goal = goal

func get_duration():
	return duration

func get_set_variables():
	var variables = {}
	return variables

func get_get_variables():
	var variables = {
		"duration":  funcref(self, "get_duration")
	}
	return variables
	
func get_objects():
	var objects = [box, goal]
	return objects
	
func start_simulation():
	endTimer.start(duration)
	box.start()

func _on_goal_entered(object):
	onGoal = true

func _on_goal_exited(object):
	onGoal = false

func _on_Timer_timeout():
	emit_signal("simulationEnd", onGoal)
	box.stop()

	