extends Control

# Pet selection data
var starter_pets: Array[Pet] = []
var selected_pet: Pet = null
var selected_pet_index: int = -1

# UI references
@onready var pet1_image: TextureRect = $MainContainer/PetOptionsContainer/Pet1Option/Pet1Content/Pet1Image
@onready var pet2_image: TextureRect = $MainContainer/PetOptionsContainer/Pet2Option/Pet2Content/Pet2Image
@onready var pet3_image: TextureRect = $MainContainer/PetOptionsContainer/Pet3Option/Pet3Content/Pet3Image

@onready var pet1_option: Panel = $MainContainer/PetOptionsContainer/Pet1Option
@onready var pet2_option: Panel = $MainContainer/PetOptionsContainer/Pet2Option
@onready var pet3_option: Panel = $MainContainer/PetOptionsContainer/Pet3Option

@onready var selected_pet_label: Label = $MainContainer/BottomContainer/SelectedPetLabel
@onready var confirm_button: Button = $MainContainer/BottomContainer/ConfirmButton

# Style boxes for selection feedback
var normal_style: StyleBoxFlat
var selected_style: StyleBoxFlat

# Signals
signal pet_selected(pet: Pet)
signal selection_confirmed(pet: Pet)

func _ready():
	_setup_styles()
	_create_starter_pets()
	_setup_pet_display()
	_show_welcome_message()
	_animate_screen_entrance()

func _animate_screen_entrance():
	"""Animate the pet options sliding in for a nice entrance effect"""
	# Wait for one frame to ensure layout is calculated
	await get_tree().process_frame
	
	# Store original positions
	var pet1_original_x = pet1_option.position.x
	var pet2_original_y = pet2_option.position.y
	var pet3_original_x = pet3_option.position.x
	
	# Start with pet options slightly transparent and offset
	pet1_option.modulate.a = 0.0
	pet2_option.modulate.a = 0.0
	pet3_option.modulate.a = 0.0
	
	# Use offset properties for Control nodes
	pet1_option.position.x = pet1_original_x - 50
	pet2_option.position.y = pet2_original_y - 30
	pet3_option.position.x = pet3_original_x + 50
	
	# Animate them sliding in with staggered timing
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Pet 1 slides in from left
	tween.tween_property(pet1_option, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tween.tween_property(pet1_option, "position:x", pet1_original_x, 0.5).set_delay(0.2)
	
	# Pet 2 slides in from top
	tween.tween_property(pet2_option, "modulate:a", 1.0, 0.5).set_delay(0.4)
	tween.tween_property(pet2_option, "position:y", pet2_original_y, 0.5).set_delay(0.4)
	
	# Pet 3 slides in from right
	tween.tween_property(pet3_option, "modulate:a", 1.0, 0.5).set_delay(0.6)
	tween.tween_property(pet3_option, "position:x", pet3_original_x, 0.5).set_delay(0.6)

func _show_welcome_message():
	"""Show a welcome message for new players"""
	selected_pet_label.text = "Welcome, Trainer! Choose your first companion to begin your journey."

func _setup_styles():
	"""Create style boxes for normal and selected states"""
	# Normal style (matches the scene)
	normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.15, 0.25, 1)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.3, 0.3, 0.5, 1)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.corner_radius_bottom_left = 8
	
	# Selected style
	selected_style = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.2, 0.3, 0.5, 1)
	selected_style.border_width_left = 3
	selected_style.border_width_top = 3
	selected_style.border_width_right = 3
	selected_style.border_width_bottom = 3
	selected_style.border_color = Color(0.4, 0.6, 1.0, 1)
	selected_style.corner_radius_top_left = 8
	selected_style.corner_radius_top_right = 8
	selected_style.corner_radius_bottom_right = 8
	selected_style.corner_radius_bottom_left = 8

func _create_starter_pets():
	"""Create the three starter pet options"""
	# Load starter pets from resources
	var pet1 = load("res://Resources/Pet/Flametail.tres") as Pet
	var pet2 = load("res://Resources/Pet/Aquashield.tres") as Pet  
	var pet3 = load("res://Resources/Pet/Voltdash.tres") as Pet
	
	starter_pets = [pet1, pet2, pet3]

func _setup_pet_display():
	"""Set up the visual display of the three pets"""
	if starter_pets.size() >= 3:
		# Set pet images
		if starter_pets[0].texture_card:
			pet1_image.texture = starter_pets[0].texture_card
		if starter_pets[1].texture_card:
			pet2_image.texture = starter_pets[1].texture_card
		if starter_pets[2].texture_card:
			pet3_image.texture = starter_pets[2].texture_card

func _update_selection_visual():
	"""Update the visual feedback for pet selection"""
	# Reset all panels to normal style
	pet1_option.set("theme_override_styles/panel", normal_style)
	pet2_option.set("theme_override_styles/panel", normal_style)
	pet3_option.set("theme_override_styles/panel", normal_style)
	
	# Highlight selected panel
	match selected_pet_index:
		0:
			pet1_option.set("theme_override_styles/panel", selected_style)
		1:
			pet2_option.set("theme_override_styles/panel", selected_style)
		2:
			pet3_option.set("theme_override_styles/panel", selected_style)

func _update_selection_info():
	"""Update the selection info display"""
	if selected_pet:
		selected_pet_label.text = "Selected: " + selected_pet.name
		confirm_button.disabled = false
	else:
		selected_pet_label.text = "Select a pet to continue..."
		confirm_button.disabled = true

func _on_pet_1_selected():
	"""Handle Pet 1 (Flametail) selection"""
	selected_pet = starter_pets[0]
	selected_pet_index = 0
	_update_selection_visual()
	_update_selection_info()
	pet_selected.emit(selected_pet)
	print("Selected: ", selected_pet.name)

func _on_pet_2_selected():
	"""Handle Pet 2 (Aquashield) selection"""
	selected_pet = starter_pets[1]
	selected_pet_index = 1
	_update_selection_visual()
	_update_selection_info()
	pet_selected.emit(selected_pet)
	print("Selected: ", selected_pet.name)

func _on_pet_3_selected():
	"""Handle Pet 3 (Voltdash) selection"""
	selected_pet = starter_pets[2]
	selected_pet_index = 2
	_update_selection_visual()
	_update_selection_info()
	pet_selected.emit(selected_pet)
	print("Selected: ", selected_pet.name)

func _on_confirm_button_pressed():
	"""Handle confirm button press"""
	if selected_pet:
		_confirm_selection()

func _confirm_selection():
	"""Confirm the pet selection and proceed"""
	if not selected_pet:
		return
	
	# Add the selected pet to the player's team
	if GlobalPlayer:
		# Clear existing pets and add the starter
		GlobalPlayer.playerTeam.clear()
		GlobalPlayer.playerTeam.append(selected_pet)
		print("Added ", selected_pet.name, " to player's team")
	
	# Emit confirmation signal
	selection_confirmed.emit(selected_pet)
	
	# Transition to the next scene (e.g., overworld or main game)
	_go_to_overworld()

func _go_to_overworld():
	"""Transition to the overworld scene"""
	# Show a brief confirmation message
	selected_pet_label.text = "Welcome to your adventure with " + selected_pet.name + "!"
	confirm_button.disabled = true
	
	# Brief delay before transitioning
	await get_tree().create_timer(1.5).timeout
	
	# Check if SceneManager is available
	if SceneManager:
		SceneManager.change_scene("res://Scenes/Screens/Overworld/Overworld.tscn")
	else:
		# Fallback: direct scene change
		get_tree().change_scene_to_file("res://Scenes/Screens/Overworld/Overworld.tscn")

func _on_back_button_pressed():
	"""Handle back button press"""
	# Go back to main menu
	if SceneManager:
		SceneManager.change_scene("res://Scenes/Screens/MainMenu/MainMenu.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Screens/MainMenu/MainMenu.tscn")

# Optional: Handle keyboard input for quick selection
func _input(event):
	"""Handle keyboard input for pet selection"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_pet_1_selected()
			KEY_2:
				_on_pet_2_selected()
			KEY_3:
				_on_pet_3_selected()
			KEY_ENTER, KEY_KP_ENTER:
				if not confirm_button.disabled:
					_on_confirm_button_pressed()
			KEY_ESCAPE:
				_on_back_button_pressed()

# Helper function to get the selected pet (for external use)
func get_selected_pet() -> Pet:
	return selected_pet

# Function to reset selection (for external use)
func reset_selection():
	selected_pet = null
	selected_pet_index = -1
	_update_selection_visual()
	_update_selection_info()
