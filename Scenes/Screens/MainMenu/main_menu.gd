extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_new_game_pressed():
	SceneManager.change_scene("res://Scenes/Screens/Overworld/Overworld.tscn")


func _on_continue_pressed():
	SceneManager.change_scene("res://Scenes/Screens/Overworld/Overworld.tscn")
