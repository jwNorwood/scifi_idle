extends Control

signal skill_selected(skill_index: int, skill_data)
signal modal_closed()

@onready var background: ColorRect = $Background
@onready var skill_option_1: Panel = %SkillOption1
@onready var skill_option_2: Panel = %SkillOption2
@onready var skill_option_3: Panel = %SkillOption3

# Skill option components for option 1
@onready var skill_icon_1: TextureRect = skill_option_1.get_node("VBoxContainer/HBoxContainer/SkillIcon")
@onready var skill_name_1: Label = skill_option_1.get_node("VBoxContainer/HBoxContainer/SkillInfo/SkillName")
@onready var skill_description_1: Label = skill_option_1.get_node("VBoxContainer/HBoxContainer/SkillInfo/SkillDescription")
@onready var select_button_1: Button = skill_option_1.get_node("VBoxContainer/SelectButton")

# Skill option components for option 2
@onready var skill_icon_2: TextureRect = skill_option_2.get_node("VBoxContainer/HBoxContainer/SkillIcon")
@onready var skill_name_2: Label = skill_option_2.get_node("VBoxContainer/HBoxContainer/SkillInfo/SkillName")
@onready var skill_description_2: Label = skill_option_2.get_node("VBoxContainer/HBoxContainer/SkillInfo/SkillDescription")
@onready var select_button_2: Button = skill_option_2.get_node("VBoxContainer/SelectButton")

# Skill option components for option 3
@onready var skill_icon_3: TextureRect = skill_option_3.get_node("VBoxContainer/HBoxContainer/SkillIcon")
@onready var skill_name_3: Label = skill_option_3.get_node("VBoxContainer/HBoxContainer/SkillInfo/SkillName")
@onready var skill_description_3: Label = skill_option_3.get_node("VBoxContainer/HBoxContainer/SkillInfo/SkillDescription")
@onready var select_button_3: Button = skill_option_3.get_node("VBoxContainer/SelectButton")

var skill_options: Array = []
var normal_style: StyleBox
var hover_style: StyleBox
var selected_style: StyleBox

func _ready():
	# Hide the modal initially
	visible = false
	
	# Connect background click to close modal
	if background:
		background.gui_input.connect(_on_background_clicked)
	
	# Create visual styles for skill options
	_setup_styles()
	
	# Connect hover events for visual feedback
	_setup_hover_effects()

func _setup_styles():
	# Normal style
	normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.4, 0.4, 0.4)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	
	# Hover style
	hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(0.6, 0.6, 0.6)
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	
	# Selected/highlighted style
	selected_style = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.2, 0.5, 0.8, 0.9)
	selected_style.border_width_left = 3
	selected_style.border_width_right = 3
	selected_style.border_width_top = 3
	selected_style.border_width_bottom = 3
	selected_style.border_color = Color(0.4, 0.7, 1.0)
	selected_style.corner_radius_top_left = 8
	selected_style.corner_radius_top_right = 8
	selected_style.corner_radius_bottom_left = 8
	selected_style.corner_radius_bottom_right = 8
	
	# Apply normal style to all options initially
	skill_option_1.add_theme_stylebox_override("panel", normal_style)
	skill_option_2.add_theme_stylebox_override("panel", normal_style)
	skill_option_3.add_theme_stylebox_override("panel", normal_style)

func _setup_hover_effects():
	# Connect mouse enter/exit events for hover effects
	skill_option_1.mouse_entered.connect(_on_option_hover.bind(skill_option_1))
	skill_option_1.mouse_exited.connect(_on_option_unhover.bind(skill_option_1))
	
	skill_option_2.mouse_entered.connect(_on_option_hover.bind(skill_option_2))
	skill_option_2.mouse_exited.connect(_on_option_unhover.bind(skill_option_2))
	
	skill_option_3.mouse_entered.connect(_on_option_hover.bind(skill_option_3))
	skill_option_3.mouse_exited.connect(_on_option_unhover.bind(skill_option_3))

func _on_option_hover(option: Panel):
	option.add_theme_stylebox_override("panel", hover_style)

func _on_option_unhover(option: Panel):
	option.add_theme_stylebox_override("panel", normal_style)

func show_modal(skills: Array):
	"""
	Show the modal with the given skill options.
	skills should be an array of skill data (could be resources, dictionaries, etc.)
	"""
	if skills.size() != 3:
		push_error("SkillSelectModal requires exactly 3 skill options")
		return
	
	skill_options = skills
	_populate_skill_options()
	visible = true

func _populate_skill_options():
	"""Fill in the skill option UI with the provided skill data"""
	
	# For now, we'll assume skills are dictionaries with name, description, and icon
	# You can modify this based on your actual skill data structure
	
	if skill_options.size() >= 1:
		_set_skill_option_data(0, skill_options[0])
	
	if skill_options.size() >= 2:
		_set_skill_option_data(1, skill_options[1])
	
	if skill_options.size() >= 3:
		_set_skill_option_data(2, skill_options[2])

func _set_skill_option_data(option_index: int, skill_data):
	"""Set the data for a specific skill option"""
	var skill_name: String = ""
	var skill_description: String = ""
	var skill_icon: Texture2D = null
	
	# Handle different skill data formats
	if skill_data is Dictionary:
		skill_name = skill_data.get("name", "Unknown Skill")
		skill_description = skill_data.get("description", "No description available")
		skill_icon = skill_data.get("icon", null)
	elif skill_data.has_method("get_name"):
		# Assume it's a skill resource with methods
		skill_name = skill_data.get_name()
		skill_description = skill_data.get_description()
		skill_icon = skill_data.get_icon()
	else:
		# Fallback
		skill_name = str(skill_data)
		skill_description = "Skill option " + str(option_index + 1)
	
	# Set the UI elements based on option index
	match option_index:
		0:
			skill_name_1.text = skill_name
			skill_description_1.text = skill_description
			if skill_icon:
				skill_icon_1.texture = skill_icon
		1:
			skill_name_2.text = skill_name
			skill_description_2.text = skill_description
			if skill_icon:
				skill_icon_2.texture = skill_icon
		2:
			skill_name_3.text = skill_name
			skill_description_3.text = skill_description
			if skill_icon:
				skill_icon_3.texture = skill_icon

func _on_skill_selected(skill_index: int):
	"""Handle when a skill is selected"""
	if skill_index >= 0 and skill_index < skill_options.size():
		skill_selected.emit(skill_index, skill_options[skill_index])
		_close_modal()

func _on_cancel_button_pressed():
	"""Handle cancel button press"""
	_close_modal()

func _on_background_clicked(event: InputEvent):
	"""Handle clicking on the background to close modal"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_modal()

func _close_modal():
	"""Close the modal and emit signal"""
	visible = false
	modal_closed.emit()

# Example function to show test skills
func show_test_skills():
	"""For testing purposes - shows 3 example skills"""
	var test_skills = [
		{
			"name": "Fireball",
			"description": "Launch a powerful fireball that deals fire damage to enemies.",
			"icon": null
		},
		{
			"name": "Heal",
			"description": "Restore health to yourself or an ally.",
			"icon": null
		},
		{
			"name": "Lightning Bolt",
			"description": "Strike enemies with a bolt of lightning, dealing electrical damage.",
			"icon": null
		}
	]
	show_modal(test_skills)
