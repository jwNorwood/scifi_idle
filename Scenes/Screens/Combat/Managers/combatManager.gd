extends Node

@onready var victoryModal = %VictoryModal
@onready var button = %Button
@onready var parent = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func onGameEnd(victory):
	print("victory ", victory)
	victoryModal.show()

func returnToOverworld():
	# change the scene
	self.get_parent().queue_free()
	# something else	


func _on_button_pressed():
	returnToOverworld()
