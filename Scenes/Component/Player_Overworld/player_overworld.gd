extends Sprite2D
class_name OverworldPlayer

@export var currentEncounterId: int = 0
@export var current_team = []
@export var gold: int = 0

var destination
var gap: Vector2
var speed: int = 0

signal travel_finished

func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (destination):
		global_position += gap * speed * delta
		if (global_position.distance_to(destination) < 1):
			global_position = destination
			destination = null
			speed = 0
			emit_signal("travel_finished")

func travelToEncounter(id, location):
	currentEncounterId = id
	destination = location
	gap = (destination - global_position) / 100
	speed = 100
