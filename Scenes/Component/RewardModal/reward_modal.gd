extends Control

var rewards = []



func closeModal():
	print("close")
	
func openModal():
	print("open modal")

func setRewards(newRewards):
	print("rewards", newRewards)

func takeAllRewards():
	print("yoink")
	EventBus.player_gold_change.emit(10)
	self.visible = false


func _on_take_all_pressed():
	takeAllRewards()

func _on_reward_pressed():
	print("single reward")
