extends Node

@onready var rewardModal = %RewardModal
@onready var parent = $".."
@onready var exitToHome = %Exit

var expToReward: int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func onGameEnd(victory):
	print("victory ", victory)
	EventBus.player_experience_change.emit(expToReward)
	rewardModal.show()
	exitToHome.show()

func returnToOverworld():
	# change the scene
	self.get_parent().queue_free()
	# something else
	#on modal closed	

func _on_exit_pressed():
	returnToOverworld()
