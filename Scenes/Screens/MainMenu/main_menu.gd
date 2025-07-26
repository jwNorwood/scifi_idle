extends Node

@onready var continue_button: Button = $HBoxContainer/MarginContainer/VBoxContainer/Continue

# Called when the node enters the scene tree for the first time.
func _ready():
	_check_save_data()

func _check_save_data():
	"""Check if there's existing save data and update continue button accordingly"""
	# For now, check if player has any pets in their team
	if GlobalPlayer and not GlobalPlayer.playerTeam.is_empty():
		continue_button.disabled = false
		continue_button.text = "Continue"
	else:
		continue_button.disabled = true
		continue_button.text = "No Save Data"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_new_game_pressed():
	"""Start a new game - go to pet selection first"""
	# Clear any existing player data for a fresh start
	_reset_player_data()
	
	# Navigate to pet selection screen
	SceneManager.change_scene("res://Scenes/Screens/PetSelection/PetSelectionScreen.tscn")

func _on_continue_pressed():
	"""Continue existing game - skip pet selection and go to overworld"""
	# Load existing player data if available
	_load_player_data()
	
	# Go directly to overworld
	SceneManager.change_scene("res://Scenes/Screens/Overworld/Overworld.tscn")

func _reset_player_data():
	"""Reset player data for a new game"""
	if GlobalPlayer:
		# Clear player team and inventory
		GlobalPlayer.playerTeam.clear()
		GlobalPlayer.playerTeamInventory.clear()
		
		# Reset player stats
		GlobalPlayer.playerGold = 10
		GlobalPlayer.playerExp = 0
		GlobalPlayer.playerLevel = 1
		GlobalPlayer.playerItems.clear()
		GlobalPlayer.playerModifiers.clear()
		
		print("Player data reset for new game")

func _load_player_data():
	"""Load existing player data (placeholder for save system)"""
	# TODO: Implement save/load system
	# For now, just initialize test data if team is empty
	if GlobalPlayer and GlobalPlayer.playerTeam.is_empty():
		GlobalPlayer._init_test_data()
		print("Loaded existing player data")
