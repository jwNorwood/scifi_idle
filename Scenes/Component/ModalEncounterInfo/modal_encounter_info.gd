extends Control

@export var titleText: String = "Test"
@export var descriptionText: String = "Some more about this encounter"

@onready var title = %Title
@onready var description = %Description

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	title.text = titleText
	description.text = descriptionText
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func setTitle(newText: String):
	title.text = newText

func setDescription(newText: String):
	description.text = newText
