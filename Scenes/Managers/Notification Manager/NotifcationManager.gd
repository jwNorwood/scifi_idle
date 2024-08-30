extends Node

@export var currency: float = 1;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func updateCurrency(change: float):
	currency += change

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
