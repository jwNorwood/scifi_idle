extends Control

@onready var continue_button: Button = $MainContainer/CenterContainer/VBoxContainer/MenuButtons/Continue
@onready var status_label: Label = $MainContainer/CenterContainer/VBoxContainer/FooterSection/StatusLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	_check_save_data()
	_add_button_animations()

func _check_save_data():
	"""Check if there's existing save data and update continue button accordingly"""
	# For now, check if player has any pets in their team
	if GlobalPlayer and not GlobalPlayer.playerTeam.is_empty():
		continue_button.disabled = false
		continue_button.text = "📁 Continue"
		status_label.text = "Welcome back, Trainer!"
	else:
		continue_button.disabled = true
		continue_button.text = "📁 No Save Data"
		status_label.text = "Ready to begin your adventure!"

func _add_button_animations():
	"""Add hover animations to buttons"""
	var buttons = [
		$MainContainer/CenterContainer/VBoxContainer/MenuButtons/NewGame,
		$MainContainer/CenterContainer/VBoxContainer/MenuButtons/Continue,
		$MainContainer/CenterContainer/VBoxContainer/MenuButtons/Atlas,
		$MainContainer/CenterContainer/VBoxContainer/MenuButtons/Settings
	]
	
	for button in buttons:
		if button:
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button: Button):
	"""Animate button on hover"""
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_unhover(button: Button):
	"""Animate button when hover ends"""
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

# Button signal handlers
func _on_new_game_pressed():
	"""Start a new game"""
	# Reset player data for new game
	GlobalPlayer.playerTeam.clear()
	GlobalPlayer.playerTeamInventory.clear()
	
	# Navigate to pet selection screen for initial pet choice
	SceneManager.change_scene("res://Scenes/Screens/PetSelection/PetSelectionScreen.tscn")

func _on_continue_pressed():
	"""Continue existing game"""
	if not GlobalPlayer.playerTeam.is_empty():
		SceneManager.change_scene("res://Scenes/Screens/Overworld/Overworld.tscn")

func _on_atlas_pressed():
	"""Open pet atlas/collection screen"""
	# TODO: Create and navigate to pet atlas screen
	print("Atlas functionality coming soon!")

func _on_settings_pressed():
	"""Open settings screen"""
	SceneManager.change_scene("res://Scenes/Screens/Settings/Settings.tscn")
