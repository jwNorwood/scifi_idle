extends Node

@onready var rewardModal = %RewardModal
@onready var parent = $".."
@onready var exitToHome = %Exit
@onready var dialogue = %Dialogue

# Combat participants
@onready var player_combat: Player = get_tree().get_first_node_in_group("player")
@onready var enemy_combat: Player = get_tree().get_first_node_in_group("enemy")

var expToReward: int = 1
var defeated_wild_pets: Array[Pet] = []
var game_ended: bool = false  # Flag to prevent multiple reward modal calls
var combat_started: bool = false  # Flag to track if combat has actually started
var defeated_regional_champion: bool = false  # Flag to track if we defeated a Regional Champion

# Available enemy pets for random encounters
var wild_pet_pool: Array[Pet] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	_setup_combat()

func _setup_combat():
	"""Initialize combat with player's actual team and random enemy"""
	game_ended = false  # Reset game ended flag for new combat
	combat_started = false
	defeated_regional_champion = false  # Reset Regional Champion flag
	
	# Check if we're fighting a Regional Champion
	var encounter_type = GlobalPlayer.current_encounter_type if GlobalPlayer else "WILD"
	if encounter_type == "REGIONAL_CHAMPION":
		print("Preparing for Regional Champion battle!")
	
	_create_wild_pet_pool()
	_setup_player_team()
	_setup_enemy_team()
	
	# Show opening dialogue
	_show_opening_dialogue()

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
		# Convert Array[Pet] to Array[Resource] for compatibility and apply skill modifiers
		var resource_team: Array[Resource] = []
		for pet in GlobalPlayer.playerTeam:
			if pet:
				# Create a copy of the pet to avoid modifying the original
				var combat_pet = Pet.new()
				combat_pet.name = pet.name
				combat_pet.attack = pet.attack
				combat_pet.health = pet.health
				combat_pet.speed = pet.speed
				combat_pet.mana_max = pet.mana_max
				combat_pet.mana_attack = pet.mana_attack
				combat_pet.mana_start = pet.mana_start
				combat_pet.texture_card = pet.texture_card
				combat_pet.special_attacks = pet.special_attacks
				combat_pet.active_special_attack = pet.active_special_attack
				
				# Apply skill modifiers
				if GlobalPlayer.skill_manager:
					combat_pet = GlobalPlayer.skill_manager.apply_pet_modifiers(combat_pet)
				
				resource_team.append(combat_pet as Resource)
		
		player_combat.team = resource_team
		print("Player team loaded: ", GlobalPlayer.playerTeam.size(), " pets (with skill modifiers)")
		for i in range(resource_team.size()):
			var pet = resource_team[i] as Pet
			if pet:
				print("  - ", pet.name, " (Health: ", pet.health, ", Attack: ", pet.attack, ")")
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
	"""Set up random enemy team based on encounter type"""
	if not enemy_combat:
		print("Warning: No enemy combat node found!")
		return
	
	# Determine team size based on encounter type
	var team_size = 1  # Default for WILD encounters
	var encounter_type = GlobalPlayer.current_encounter_type if GlobalPlayer else "WILD"
	
	print("Setting up enemy team for encounter type: ", encounter_type)
	
	match encounter_type:
		"WILD":
			team_size = 1
		"TRAINER":
			team_size = randi_range(2, 3)  # 2-3 pets for trainers
		"MYSTERY":
			team_size = randi_range(1, 2)  # 1-2 pets for mystery encounters
		"REGIONAL_CHAMPION":
			team_size = 5  # Full team of 5 pets for Regional Champions
		_:
			team_size = 1
	
	# Generate enemy team
	var enemy_team: Array[Resource] = []
	
	# Clear previous defeated pets list
	defeated_wild_pets.clear()
	
	for i in range(team_size):
		var random_pet = _get_random_wild_pet()
		
		# Make Regional Champion pets stronger
		if encounter_type == "REGIONAL_CHAMPION":
			random_pet = _create_champion_pet(random_pet)
		
		enemy_team.append(random_pet as Resource)
		# Store the original pet for potential capture
		defeated_wild_pets.append(random_pet)
	
	enemy_combat.team = enemy_team
	print("Enemy team generated: ", enemy_team.size(), " pets for ", encounter_type, " encounter")
	for pet_resource in enemy_team:
		var pet = pet_resource as Pet
		if pet:
			print("  - ", pet.name, " (Health: ", pet.health, ", Attack: ", pet.attack, ")")

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

func _create_champion_pet(base_pet: Pet) -> Pet:
	"""Create a stronger version of a pet for Regional Champion encounters"""
	var champion_pet = Pet.new()
	champion_pet.name = "Champion " + base_pet.name
	champion_pet.texture_card = base_pet.texture_card
	
	# Make champion pets significantly stronger (150-200% of base stats)
	var champion_factor = randf_range(1.5, 2.0)
	champion_pet.attack = base_pet.attack * champion_factor
	champion_pet.health = int(base_pet.health * champion_factor)
	champion_pet.speed = base_pet.speed * champion_factor
	champion_pet.mana_max = int(base_pet.mana_max * champion_factor)
	champion_pet.mana_attack = base_pet.mana_attack
	champion_pet.mana_start = champion_pet.mana_max
	
	return champion_pet

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
	
	# Check if we defeated a Regional Champion
	var encounter_type = GlobalPlayer.current_encounter_type if GlobalPlayer else "WILD"
	if victory and encounter_type == "REGIONAL_CHAMPION":
		defeated_regional_champion = true
		print("Regional Champion defeated! New map will be generated after exit.")
	
	EventBus.player_experience_change.emit(expToReward)
	
	if victory:
		_show_victory_dialogue()
	else:
		_show_defeat_dialogue()
	
	exitToHome.show()

func _handle_victory_rewards():
	"""Handle rewards for winning combat"""
	var encounter_type = GlobalPlayer.current_encounter_type if GlobalPlayer else "WILD"
	
	# Calculate rewards based on encounter type
	var gold_reward = 10  # Base gold reward
	var experience_multiplier = 1.0
	
	match encounter_type:
		"WILD":
			gold_reward = randi_range(10, 25)
			experience_multiplier = 1.0
		"TRAINER":
			gold_reward = randi_range(25, 50)
			experience_multiplier = 1.5
		"MYSTERY":
			gold_reward = randi_range(15, 35)
			experience_multiplier = 1.2
		"REGIONAL_CHAMPION":
			gold_reward = randi_range(100, 200)  # Much higher gold reward
			experience_multiplier = 3.0  # Triple experience
		_:
			gold_reward = randi_range(10, 25)
			experience_multiplier = 1.0
	
	# Apply experience multiplier
	expToReward = int(expToReward * experience_multiplier)
	
	# Apply skill modifiers to rewards
	if GlobalPlayer and GlobalPlayer.skill_manager:
		gold_reward = GlobalPlayer.skill_manager.calculate_final_gold_reward(gold_reward)
		expToReward = GlobalPlayer.skill_manager.calculate_final_experience(expToReward)
		print("Applied skill modifiers - Gold: ", gold_reward, ", Experience: ", expToReward)
	
	# Always reward pets after combat victory
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
	# Check if this was the initial pet combat
	var is_initial_combat = GlobalPlayer.has_selected_initial_pet if GlobalPlayer else false
	
	# If we defeated a Regional Champion, request map regeneration
	if defeated_regional_champion:
		print("Requesting new map generation after Regional Champion victory!")
		EventBus.map_regeneration_requested.emit()
	
	# For initial combat, go to overworld; otherwise return to previous scene
	if is_initial_combat and GlobalPlayer:
		# Mark that we've completed the initial combat flow
		GlobalPlayer.has_selected_initial_pet = false  # Reset the flag
		print("Initial combat completed, transitioning to overworld...")
		
		# Go to overworld scene
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/Screens/Overworld/Overworld.tscn")
	else:
		# Normal combat exit - just close the combat scene
		self.get_parent().queue_free()
	
	# something else
	#on modal closed	

func _on_exit_pressed():
	returnToOverworld()

func _show_opening_dialogue():
	"""Show dialogue at the start of combat"""
	if not dialogue:
		print("Warning: Dialogue component not found!")
		_start_combat()
		return
	
	var encounter_type = GlobalPlayer.current_encounter_type if GlobalPlayer else "WILD"
	var is_initial_combat = GlobalPlayer.has_selected_initial_pet if GlobalPlayer else false
	var enemy_name = "Wild Creature"
	
	# Get enemy name from the enemy team
	if enemy_combat and not enemy_combat.team.is_empty():
		var enemy_pet = enemy_combat.team[0] as Pet
		if enemy_pet:
			enemy_name = enemy_pet.name
	
	var opening_messages: Array[String] = []
	
	# Special dialogue for initial combat
	if is_initial_combat:
		opening_messages = [
			"[center][color=cyan]Time to test your new companion![/color][/center]",
			"[center][color=yellow]A wild " + enemy_name + " appears for training![/color][/center]",
			"[center][color=lime]Show them what you've learned![/color][/center]"
		]
	else:
		# Customize dialogue based on encounter type for regular combat
		match encounter_type:
			"WILD":
				opening_messages = [
					"[center][color=yellow]A wild " + enemy_name + " appears![/color][/center]",
					"[center][color=cyan]Prepare for battle![/color][/center]"
				]
			"TRAINER":
				opening_messages = [
					"[center][color=orange]A trainer challenges you to battle![/color][/center]",
					"[center][color=cyan]They have multiple pets ready to fight![/color][/center]"
				]
			"MYSTERY":
				opening_messages = [
					"[center][color=purple]A mysterious encounter unfolds...[/color][/center]",
					"[center][color=cyan]Prepare for the unknown![/color][/center]"
				]
			"REGIONAL_CHAMPION":
				opening_messages = [
					"[center][color=gold]A Regional Champion blocks your path![/color][/center]",
					"[center][color=red]They command a full team of 5 powerful Champion pets![/color][/center]",
					"[center][color=orange]This will be your greatest challenge yet![/color][/center]"
				]
			_:
				opening_messages = [
					"[center][color=yellow]A wild " + enemy_name + " appears![/color][/center]",
					"[center][color=cyan]Prepare for battle![/color][/center]"
				]
	
	# Connect to dialogue finished signal
	if not dialogue.dialogue_finished.is_connected(_on_opening_dialogue_finished):
		dialogue.dialogue_finished.connect(_on_opening_dialogue_finished)
	
	dialogue.show_messages(opening_messages, 1.5)

func _on_opening_dialogue_finished():
	"""Called when opening dialogue finishes"""
	# Disconnect the signal
	if dialogue.dialogue_finished.is_connected(_on_opening_dialogue_finished):
		dialogue.dialogue_finished.disconnect(_on_opening_dialogue_finished)
	
	_start_combat()

func _start_combat():
	"""Start the actual combat after opening dialogue"""
	combat_started = true
	print("Combat started!")
	# Combat will proceed naturally from here

func _show_victory_dialogue():
	"""Show dialogue when player wins"""
	if not dialogue:
		print("Warning: Dialogue component not found!")
		_handle_victory_rewards()
		return
	
	var encounter_type = GlobalPlayer.current_encounter_type if GlobalPlayer else "WILD"
	var is_initial_combat = GlobalPlayer.has_selected_initial_pet if GlobalPlayer else false
	var victory_messages: Array[String] = []
	
	# Special dialogue for initial combat victory
	if is_initial_combat:
		victory_messages = [
			"[center][color=gold]Excellent work![/color][/center]",
			"[center][color=lime]You and your companion fought well together![/color][/center]",
			"[center][color=cyan]You're ready for the adventures ahead![/color][/center]"
		]
	else:
		# Customize victory dialogue based on encounter type for regular combat
		match encounter_type:
			"WILD":
				victory_messages = [
					"[center][color=green]Victory![/color][/center]",
					"[center][color=lime]You defeated the wild creature![/color][/center]"
				]
			"TRAINER":
				victory_messages = [
					"[center][color=green]Victory![/color][/center]",
					"[center][color=lime]You defeated the trainer and their team![/color][/center]"
				]
			"MYSTERY":
				victory_messages = [
					"[center][color=green]Victory![/color][/center]",
					"[center][color=lime]You overcame the mysterious challenge![/color][/center]"
				]
			"REGIONAL_CHAMPION":
				victory_messages = [
					"[center][color=gold]LEGENDARY VICTORY![/color][/center]",
					"[center][color=yellow]You defeated the Regional Champion![/color][/center]",
					"[center][color=lime]You are now a true champion yourself![/color][/center]",
					"[center][color=cyan]A new area awaits your exploration![/color][/center]"
				]
			_:
				victory_messages = [
					"[center][color=green]Victory![/color][/center]",
					"[center][color=lime]You defeated the wild creature![/color][/center]"
				]
	
	# Connect to dialogue finished signal
	if not dialogue.dialogue_finished.is_connected(_on_victory_dialogue_finished):
		dialogue.dialogue_finished.connect(_on_victory_dialogue_finished)
	
	dialogue.show_messages(victory_messages, 1.5)

func _on_victory_dialogue_finished():
	"""Called when victory dialogue finishes"""
	# Disconnect the signal
	if dialogue.dialogue_finished.is_connected(_on_victory_dialogue_finished):
		dialogue.dialogue_finished.disconnect(_on_victory_dialogue_finished)
	
	_handle_victory_rewards()

func _show_defeat_dialogue():
	"""Show dialogue when player loses"""
	if not dialogue:
		print("Warning: Dialogue component not found!")
		_handle_defeat()
		return
	
	var defeat_messages: Array[String] = [
		"[center][color=red]Defeat...[/color][/center]",
		"[center][color=orange]Your team was overwhelmed![/color][/center]"
	]
	
	# Connect to dialogue finished signal
	if not dialogue.dialogue_finished.is_connected(_on_defeat_dialogue_finished):
		dialogue.dialogue_finished.connect(_on_defeat_dialogue_finished)
	
	dialogue.show_messages(defeat_messages, 1.5)

func _on_defeat_dialogue_finished():
	"""Called when defeat dialogue finishes"""
	# Disconnect the signal
	if dialogue.dialogue_finished.is_connected(_on_defeat_dialogue_finished):
		dialogue.dialogue_finished.disconnect(_on_defeat_dialogue_finished)
	
	_handle_defeat()
