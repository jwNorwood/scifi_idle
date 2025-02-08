class_name State

extends Node

var parent
var active: bool = false

func enter() -> void:
	active = true
	pass
	
func exit() -> void:
	active = false
	pass

func processPhysics(delta: float) -> State:
	return null
		
func processInput(event: InputEvent) -> State:
	return null
		
func processFrame(delta: float) -> State:
	return null
 
