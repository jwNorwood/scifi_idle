extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	if !FileAccess.file_exists("res://SavedGame.tscn"):
		pass
	else:
		var new_scene = ResourceLoader.load("res://SavedGame.tscn")
		print("what is", get_tree().get_root())
		get_tree().get_root().add_child(new_scene)
		get_tree().get_root().get_child(0).queue_free()

func save():
	var nodeToSave = self
	var scene = PackedScene.new()
	scene.pack(nodeToSave)
	ResourceSaver.save(scene, "res://SavedGame.tscn")
