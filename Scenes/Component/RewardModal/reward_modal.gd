extends Control

var rewards = []
var pet_rewards: Array[Pet] = []
var gold_reward: int = 0

@onready var rewards_container = $Panel/MarginContainer/VBoxContainer/Rewards
@onready var take_all_button = %"Take All"

func closeModal():
	print("close")
	visible = false
	
func openModal():
	print("open modal")
	visible = true

func setRewards(newRewards):
	print("rewards", newRewards)
	rewards = newRewards
	_display_rewards()

func setPetRewards(pets: Array[Pet], gold: int = 10):
	"""Set pet rewards from combat victory"""
	pet_rewards = pets
	gold_reward = gold
	_display_pet_rewards()
	openModal()

func _display_pet_rewards():
	"""Display pet and gold rewards in the UI"""
	# Clear existing rewards
	for child in rewards_container.get_children():
		if child.name != "Reward":  # Keep the template
			child.queue_free()
	
	# Add pet rewards
	for pet in pet_rewards:
		_create_pet_reward_item(pet)
	
	# Add gold reward
	if gold_reward > 0:
		_create_gold_reward_item(gold_reward)

func _create_pet_reward_item(pet: Pet):
	"""Create a reward item for a captured pet"""
	var reward_item = preload("res://Scenes/Component/RewardModal/reward.tscn").instantiate()
	reward_item.text = "New Pet: " + pet.name
	reward_item.name = "PetReward_" + pet.name
	
	# Store pet data on the button for later retrieval
	reward_item.set_meta("pet_data", pet)
	reward_item.set_meta("reward_type", "pet")
	
	# Connect the individual reward button
	reward_item.pressed.connect(_on_pet_reward_taken.bind(reward_item))
	
	rewards_container.add_child(reward_item)

func _create_gold_reward_item(amount: int):
	"""Create a reward item for gold"""
	var reward_item = preload("res://Scenes/Component/RewardModal/reward.tscn").instantiate()
	reward_item.text = "Gold: " + str(amount)
	reward_item.name = "GoldReward"
	
	reward_item.set_meta("gold_amount", amount)
	reward_item.set_meta("reward_type", "gold")
	
	# Connect the individual reward button
	reward_item.pressed.connect(_on_gold_reward_taken.bind(reward_item))
	
	rewards_container.add_child(reward_item)

func _on_pet_reward_taken(reward_button: Button):
	"""Handle individual pet reward taken"""
	var pet = reward_button.get_meta("pet_data") as Pet
	if pet:
		_add_pet_to_player_team(pet)
		reward_button.queue_free()
		print("Pet added to team: ", pet.name)

func _on_gold_reward_taken(reward_button: Button):
	"""Handle individual gold reward taken"""
	var amount = reward_button.get_meta("gold_amount", 0)
	if amount > 0:
		EventBus.player_gold_change.emit(amount)
		reward_button.queue_free()
		print("Gold collected: ", amount)

func _add_pet_to_player_team(pet: Pet):
	"""Add a captured pet to the player's team or inventory"""
	if not GlobalPlayer:
		print("Warning: GlobalPlayer not found!")
		return
	
	# Check if player's team has space (max 5 pets in active team)
	if GlobalPlayer.playerTeam.size() < 5:
		GlobalPlayer.playerTeam.append(pet)
		print("Pet added to active team: ", pet.name)
	else:
		# Add to inventory if team is full
		GlobalPlayer.playerTeamInventory.append(pet)
		print("Pet added to inventory: ", pet.name)
	
	# Emit signal for other systems to update
	EventBus.player_team_change.emit(GlobalPlayer.playerTeam)

func _display_rewards():
	"""Legacy method for backwards compatibility"""
	# Implementation for old reward system if needed
	pass

func takeAllRewards():
	"""Take all rewards at once"""
	# Take all pet rewards
	for pet in pet_rewards:
		_add_pet_to_player_team(pet)
	
	# Take gold reward
	if gold_reward > 0:
		EventBus.player_gold_change.emit(gold_reward)
	
	print("All rewards taken: ", pet_rewards.size(), " pets, ", gold_reward, " gold")
	
	# Clear rewards and close modal
	pet_rewards.clear()
	gold_reward = 0
	closeModal()

func _on_take_all_pressed():
	takeAllRewards()

func _on_reward_pressed():
	print("single reward")
