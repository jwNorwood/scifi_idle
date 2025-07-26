extends Node

@onready var rewardModal = %RewardModal
@onready var parent = $".."
@onready var exitToHome = %Exit

# Combat participants
@onready var player_combat: Player = get_tree().get_first_node_in_group("player")
@onready var enemy_combat: Player = get_tree().get_first_node_in_group("enemy")

var expToReward: int = 1
var defeated_wild_pets: Array[Pet] = []

# Available enemy pets for random encounters
var wild_pet_pool: Array[Pet] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_setup_combat()

func _setup_combat():
	"""Initialize combat with player's actual team and random enemy"""
	_create_wild_pet_pool()
	_setup_player_team()
	_setup_enemy_team()

func _create_wild_pet_pool():
	"""Create a pool of wild pets for random encounters"""
	# Wild Pet 1: Forest Sprite (Basic type)
	var wild1 = Pet.new()
	wild1.name = "Forest Sprite"
	wild1.attack = 8.0
	wild1.health = 60
	wild1.speed = 14.0
	wild1.mana_max = 10
	wild1.mana_attack = 2
	wild1.mana_start = 10
	
	# Wild Pet 2: Rock Golem (Earth type)
	var wild2 = Pet.new()
	wild2.name = "Rock Golem"
	wild2.attack = 12.0
	wild2.health = 90
	wild2.speed = 6.0
	wild2.mana_max = 8
	wild2.mana_attack = 3
	wild2.mana_start = 8
	
	# Wild Pet 3: Wind Falcon (Air type)
	var wild3 = Pet.new()
	wild3.name = "Wind Falcon"
	wild3.attack = 10.0
	wild3.health = 50
	wild3.speed = 20.0
	wild3.mana_max = 12
	wild3.mana_attack = 2
	wild3.mana_start = 12
	
	# Wild Pet 4: Crystal Wolf (Ice type)
	var wild4 = Pet.new()
	wild4.name = "Crystal Wolf"
	wild4.attack = 11.0
	wild4.health = 70
	wild4.speed = 16.0
	wild4.mana_max = 14
	wild4.mana_attack = 3
	wild4.mana_start = 14
	
	# Wild Pet 5: Lava Salamander (Fire type)
	var wild5 = Pet.new()
	wild5.name = "Lava Salamander"
	wild5.attack = 13.0
	wild5.health = 65
	wild5.speed = 12.0
	wild5.mana_max = 16
	wild5.mana_attack = 4
	wild5.mana_start = 16
	
	# Try to load textures for wild pets (reuse existing assets)
	_try_load_wild_pet_textures([wild1, wild2, wild3, wild4, wild5])
	
	wild_pet_pool = [wild1, wild2, wild3, wild4, wild5]

func _try_load_wild_pet_textures(pets: Array[Pet]):
	"""Try to load textures for wild pets"""
	var texture_paths = [
		"res://Assets/Pet/4.png",
		"res://Assets/Pet/5.png", 
		"res://Assets/Pet/6.png",
		"res://Assets/Pet/7.png",
		"res://Assets/Pet/8.png"
	]
	
	for i in range(min(pets.size(), texture_paths.size())):
		var texture = load(texture_paths[i]) as Texture2D
		if texture:
			pets[i].texture_card = texture

func _setup_player_team():
	"""Set up player team from GlobalPlayer data"""
	if not player_combat:
		print("Warning: No player combat node found!")
		return
	
	if GlobalPlayer and not GlobalPlayer.playerTeam.is_empty():
		# Convert Array[Pet] to Array[Resource] for compatibility
		var resource_team: Array[Resource] = []
		for pet in GlobalPlayer.playerTeam:
			if pet:
				resource_team.append(pet as Resource)
		
		player_combat.team = resource_team
		print("Player team loaded: ", GlobalPlayer.playerTeam.size(), " pets")
		for pet in GlobalPlayer.playerTeam:
			print("  - ", pet.name if pet else "Unknown Pet")
	else:
		# Fallback: create a basic team if no pets exist
		print("Warning: No player team found, creating fallback team")
		_create_fallback_player_team()

func _create_fallback_player_team():
	"""Create a fallback team if player has no pets"""
	var fallback_pet = Pet.new()
	fallback_pet.name = "Basic Pet"
	fallback_pet.attack = 10.0
	fallback_pet.health = 80
	fallback_pet.speed = 10.0
	fallback_pet.mana_max = 10
	fallback_pet.mana_attack = 2
	fallback_pet.mana_start = 10
	
	# Try to load a texture
	var texture = load("res://Assets/Pet/1.png") as Texture2D
	if texture:
		fallback_pet.texture_card = texture
	
	# Convert to Array[Resource] for compatibility
	var resource_team: Array[Resource] = [fallback_pet as Resource]
	player_combat.team = resource_team
	
	# Also add to GlobalPlayer for consistency
	if GlobalPlayer:
		GlobalPlayer.playerTeam = [fallback_pet]

func _setup_enemy_team():
	"""Set up random enemy team"""
	if not enemy_combat:
		print("Warning: No enemy combat node found!")
		return
	
	# Generate 1-2 random wild pets for the enemy
	var enemy_team: Array[Resource] = []
	var team_size = randi_range(1, 2)
	
	# Clear previous defeated pets list
	defeated_wild_pets.clear()
	
	for i in range(team_size):
		var random_pet = _get_random_wild_pet()
		enemy_team.append(random_pet as Resource)
		# Store the original pet for potential capture
		defeated_wild_pets.append(random_pet)
	
	enemy_combat.team = enemy_team
	print("Enemy team generated: ", enemy_team.size(), " pets")
	for pet_resource in enemy_team:
		var pet = pet_resource as Pet
		if pet:
			print("  - ", pet.name)

func _get_random_wild_pet() -> Pet:
	"""Get a random wild pet with slight stat variation"""
	if wild_pet_pool.is_empty():
		print("Warning: Wild pet pool is empty!")
		return Pet.new()
	
	# Pick a random base pet
	var base_pet = wild_pet_pool[randi() % wild_pet_pool.size()]
	
	# Create a copy with slight variations
	var wild_pet = Pet.new()
	wild_pet.name = base_pet.name
	wild_pet.texture_card = base_pet.texture_card
	
	# Add ±20% random variation to stats
	var variation_factor = randf_range(0.8, 1.2)
	wild_pet.attack = base_pet.attack * variation_factor
	wild_pet.health = int(base_pet.health * variation_factor)
	wild_pet.speed = base_pet.speed * variation_factor
	wild_pet.mana_max = int(base_pet.mana_max * variation_factor)
	wild_pet.mana_attack = base_pet.mana_attack
	wild_pet.mana_start = wild_pet.mana_max
	
	return wild_pet

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func onGameEnd(victory):
	print("victory ", victory)
	EventBus.player_experience_change.emit(expToReward)
	
	if victory:
		_handle_victory_rewards()
	else:
		_handle_defeat()
	
	exitToHome.show()

func _handle_victory_rewards():
	"""Handle rewards for winning combat"""
	var gold_reward = randi_range(10, 25)  # Random gold between 10-25
	
	# In wild combat, player can capture defeated pets
	if not defeated_wild_pets.is_empty():
		# Chance to capture each defeated pet (70% chance per pet)
		var captured_pets: Array[Pet] = []
		
		for wild_pet in defeated_wild_pets:
			var capture_chance = randf()
			if capture_chance <= 0.7:  # 70% capture rate
				captured_pets.append(wild_pet)
				print("Captured wild pet: ", wild_pet.name)
			else:
				print("Wild pet escaped: ", wild_pet.name)
		
		# Show reward modal with captured pets
		if not captured_pets.is_empty() or gold_reward > 0:
			if rewardModal.has_method("setPetRewards"):
				rewardModal.setPetRewards(captured_pets, gold_reward)
			else:
				# Fallback for old reward system
				rewardModal.show()
				# Add pets directly if modal doesn't support new system
				for pet in captured_pets:
					_add_pet_to_team_directly(pet)
				EventBus.player_gold_change.emit(gold_reward)
		else:
			rewardModal.show()
	else:
		# No wild pets to capture, just show gold reward
		rewardModal.show()
		EventBus.player_gold_change.emit(gold_reward)

func _handle_defeat():
	"""Handle player defeat"""
	# Just show the modal, no rewards
	rewardModal.show()

func _add_pet_to_team_directly(pet: Pet):
	"""Fallback method to add pet directly to team"""
	if GlobalPlayer:
		if GlobalPlayer.playerTeam.size() < 3:
			GlobalPlayer.playerTeam.append(pet)
		else:
			GlobalPlayer.playerTeamInventory.append(pet)
		EventBus.player_team_change.emit(GlobalPlayer.playerTeam)

func returnToOverworld():
	# change the scene
	self.get_parent().queue_free()
	# something else
	#on modal closed	

func _on_exit_pressed():
	returnToOverworld()
