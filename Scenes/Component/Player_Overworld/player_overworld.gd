extends Control

@export var current_encounter_id: int = 0
@export var current_team = []
@export var gold: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func travelToNode(x, y, id):
	current_encounter_id = id
	# node.enter()
	pass
