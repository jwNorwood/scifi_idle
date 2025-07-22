extends Control

signal drag_started(pet: Pet, slot: Control)
signal pet_removed(slot_index: int)

@onready var pet_icon: TextureRect = %PetIcon
@onready var pet_name: Label = %PetName
@onready var drop_indicator: ColorRect = %DropIndicator
@onready var slot_background: Panel = $SlotBackground

var current_pet: Pet = null
var slot_index: int = -1
var is_team_slot: bool = false

# Visual states
var normal_style: StyleBox
var hover_style: StyleBox
var can_drop_style: StyleBox

func _ready():
	# Set up mouse events
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Create visual styles
	_setup_styles()
	
	# Connect to input events
	gui_input.connect(_on_gui_input)
	
	# Update display now that nodes are ready
	_update_display()

# Interface methods for centralized drag system
func is_mouse_over() -> bool:
	var mouse_pos = get_global_mouse_position()
	var rect = Rect2(global_position, size)
	return rect.has_point(mouse_pos)

func update_drag_hover(can_drop: bool):
	if can_drop:
		slot_background.add_theme_stylebox_override("panel", can_drop_style)
		drop_indicator.show()
	else:
		slot_background.add_theme_stylebox_override("panel", hover_style)
		drop_indicator.hide()

func reset_drag_appearance():
	slot_background.add_theme_stylebox_override("panel", normal_style)
	drop_indicator.hide()
	modulate = Color(1, 1, 1, 1)

func set_drag_source_appearance():
	# Make the source slot semi-transparent during drag
	modulate = Color(1, 1, 1, 0.5)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if current_pet != null:
				# Start drag through modal system
				drag_started.emit(current_pet, self)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if current_pet != null:
				_show_context_menu(event.global_position)

func _show_context_menu(_pos: Vector2):
	# For now, just remove the pet directly
	# In a full implementation, you might want a proper context menu
	pet_removed.emit(slot_index)

func set_pet(pet: Pet):
	current_pet = pet
	_update_display()

func _update_display():
	if not is_node_ready():
		return
	
	if current_pet != null:
		if pet_icon:
			pet_icon.texture = current_pet.texture_card
		if pet_name:
			pet_name.text = current_pet.name
	else:
		if pet_icon:
			pet_icon.texture = null
		if pet_name:
			pet_name.text = ""

func _setup_styles():
	# Create different visual styles for different states
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
	
	can_drop_style = StyleBoxFlat.new()
	can_drop_style.bg_color = Color(0.2, 0.6, 0.2, 0.9)
	can_drop_style.border_width_left = 3
	can_drop_style.border_width_right = 3
	can_drop_style.border_width_top = 3
	can_drop_style.border_width_bottom = 3
	can_drop_style.border_color = Color(0.4, 0.8, 0.4)
	can_drop_style.corner_radius_top_left = 8
	can_drop_style.corner_radius_top_right = 8
	can_drop_style.corner_radius_bottom_left = 8
	can_drop_style.corner_radius_bottom_right = 8
	
	# Apply normal style initially
	if slot_background:
		slot_background.add_theme_stylebox_override("panel", normal_style)

func _on_mouse_entered():
	if slot_background:
		slot_background.add_theme_stylebox_override("panel", hover_style)

func _on_mouse_exited():
	if slot_background:
		slot_background.add_theme_stylebox_override("panel", normal_style)
