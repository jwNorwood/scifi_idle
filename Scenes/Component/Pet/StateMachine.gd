extends Node

@onready var attack = $Attack

var states = [attack]

var currentState: State

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func init(parent) -> void:
	for child in get_children():
		child.parent = parent
		
	changeState(attack)
	
func changeState(newState: State) -> void:
	if currentState:
		currentState.exit()
	currentState = newState
	currentState.enter()

func processPhysics(delta: float) -> void:
	var newState = currentState.processPhysics(delta)
	if newState:
		changeState(newState)
		
func processInput(event: InputEvent) -> void:
	var newState = currentState.processInput(event)
	if newState:
		changeState(newState)
		
func processFrame(delta: float) -> void:
	var newState = currentState.processFrame(delta)
	if newState:
		changeState(newState)
		
func _process(delta):
	pass
