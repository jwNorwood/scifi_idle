extends Node

@onready var rewardModal = %RewardModal
@onready var parent = $".."
@onready var exitToHome = %Exit

# Combat participants
@onready var player_combat: Player = get_tree().get_first_node_in_group("player")
@onready var enemy_combat: Player = get_tree().get_first_node_in_group("enemy")

var expToReward: int = 1
var defeated_wild_pets: Array[Pet] = []
var game_ended: bool = false  # Flag to prevent multiple reward modal calls

# Available enemy pets for random encounters
var wild_pet_pool: Array[Pet] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_setup_combat()

func _setup_combat():
	"""Initialize combat with player's actual team and random enemy"""
	game_ended = false  # Reset game ended flag for new combat
	_create_wild_pet_pool()
	_setup_player_team()
	_setup_enemy_team()

func _create_wild_pet_pool():
	"""Create a pool of wild pets for random encounters"""
	# Load pet resources from files
	var wild1 = load("res://Resources/Pet/ForestSprite.tres") as Pet
	var wild2 = load("res://Resources/Pet/RockGolem.tres") as Pet
	var wild3 = load("res://Resources/Pet/WindFalcon.tres") as Pet
	var wild4 = load("res://Resources/Pet/CrystalWolf.tres") as Pet
	var wild5 = load("res://Resources/Pet/LavaSalamander.tres") as Pet
	
	wild_pet_pool = [wild1, wild2, wild3, wild4, wild5]

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
	var fallback_pet = load("res://Resources/Pet/BasicPet.tres") as Pet
	
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
	
	# Generate exactly 1 wild pet for the enemy (simplified combat)
	var enemy_team: Array[Resource] = []
	var team_size = 1  # Always 1 pet for both wild encounters and team battles
	
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
	# Prevent multiple calls to onGameEnd
	if game_ended:
		print("Game already ended, ignoring duplicate call")
		return
	
	game_ended = true
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
	
	# Always reward a pet after combat victory
	var captured_pets: Array[Pet] = []
	
	if not defeated_wild_pets.is_empty():
		# Guarantee capture of all defeated pets (100% capture rate)
		for wild_pet in defeated_wild_pets:
			captured_pets.append(wild_pet)
			print("Captured wild pet: ", wild_pet.name)
	else:
		# If no defeated pets (shouldn't happen), create a bonus pet
		print("No defeated pets found, generating bonus reward pet")
		var bonus_pet = _get_random_wild_pet()
		captured_pets.append(bonus_pet)
		print("Bonus reward pet: ", bonus_pet.name)
	
	# Always show reward modal with captured pets and gold
	if rewardModal.has_method("setPetRewards"):
		rewardModal.setPetRewards(captured_pets, gold_reward)
	else:
		# Fallback for old reward system
		rewardModal.show()
		# Add pets directly if modal doesn't support new system
		for pet in captured_pets:
			_add_pet_to_team_directly(pet)
		EventBus.player_gold_change.emit(gold_reward)

func _handle_defeat():
	"""Handle player defeat"""
	# Just show the modal, no rewards
	rewardModal.show()

func _add_pet_to_team_directly(pet: Pet):
	"""Fallback method to add pet directly to team"""
	if GlobalPlayer:
		if GlobalPlayer.playerTeam.size() < 5:
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
