extends Control

signal drag_started(pet: Pet, slot: Control)
signal pet_removed(slot_index: int)

@onready var pet_icon: TextureRect = %PetIcon
@onready var pet_name: Label = %PetName
@onready var drop_indicator: ColorRect = %DropIndicator
@onready var drag_preview: Control = %DragPreview
@onready var preview_icon: TextureRect = $DragPreview/PreviewIcon
@onready var slot_background: Panel = $SlotBackground

var current_pet: Pet = null
var slot_index: int = -1
var is_team_slot: bool = false

# Visual states
var normal_style: StyleBox
var hover_style: StyleBox
var can_drop_style: StyleBox

func _ready():
	# Debug: Check if nodes are found correctly
	print("PetSlot _ready() - pet_icon: ", pet_icon)
	print("PetSlot _ready() - pet_name: ", pet_name)
	
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

func set_drag_source_appearance():
	# Make the source slot semi-transparent during drag
	modulate = Color(1, 1, 1, 0.5)

func _on_gui_input(event: InputEvent):

func _process(_delta):
	# Only process during dragging to handle hover effects
	if is_dragging:
		_update_drag_hover_effect()

func _update_drag_hover_effect():
	# Check if mouse is over this slot while dragging
	var mouse_pos = get_global_mouse_position()
	var rect = Rect2(global_position, size)
	var mouse_over = rect.has_point(mouse_pos)
	
	# Update hover effect based on mouse position
	if mouse_over and not current_pet:
		# Show drop indicator for empty slots
		drop_indicator.visible = true
	else:
		drop_indicator.visible = false

func _setup_styles():
	normal_style = slot_background.get_theme_stylebox("panel")
	
	# Create hover style
	hover_style = normal_style.duplicate()
	if hover_style is StyleBoxFlat:
		hover_style.border_color = Color.CYAN
		hover_style.border_width_left = 3
		hover_style.border_width_top = 3
		hover_style.border_width_right = 3
		hover_style.border_width_bottom = 3
	
	# Create can drop style
	can_drop_style = normal_style.duplicate()
	if can_drop_style is StyleBoxFlat:
		can_drop_style.border_color = Color.GREEN
		can_drop_style.border_width_left = 3
		can_drop_style.border_width_top = 3
		can_drop_style.border_width_right = 3
		can_drop_style.border_width_bottom = 3

func set_pet(pet: Pet):
	current_pet = pet
	# Only update display if node is ready, otherwise _ready() will handle it
	if is_node_ready():
		_update_display()

func _update_display():
	print("current pet: ", current_pet )
	print("pet_icon node: ", pet_icon)
	print("pet_name node: ", pet_name)
	
	# Safety check to ensure nodes are ready
	if not is_node_ready():
		print("Node not ready yet, skipping display update")
		return
	
	# Additional safety check for node references
	if pet_icon == null:
		print("ERROR: pet_icon is null!")
		return
	if pet_name == null:
		print("ERROR: pet_name is null!")
		return
		
	if current_pet != null:
		pet_icon.texture = current_pet.texture_card
		pet_name.text = current_pet.name
		pet_icon.visible = true
	else:
		pet_icon.texture = null
		pet_name.text = "Empty"
		pet_icon.visible = false

func _on_mouse_entered():
	if current_pet != null and not is_dragging:
		slot_background.add_theme_stylebox_override("panel", hover_style)

func _on_mouse_exited():
	if not is_dragging:
		slot_background.add_theme_stylebox_override("panel", normal_style)

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

func _setup_styles():

func set_pet(pet: Pet):

func _start_drag(start_pos: Vector2):
	if current_pet == null:
		return
	
	is_dragging = true
	drag_offset = start_pos
	
	# Set up drag preview
	preview_icon.texture = current_pet.texture_card
	drag_preview.visible = true
	drag_preview.global_position = get_global_mouse_position() - Vector2(40, 50)
	
	# Visual feedback
	modulate.a = 0.5
	
	# Start monitoring for drop targets
	set_process(true)

func _update_drag(mouse_pos: Vector2):
	if not is_dragging:
		return
	
	drag_preview.global_position = get_global_mouse_position() - Vector2(40, 50)

func _end_drag():
	if not is_dragging:
		return
	
	is_dragging = false
	set_process(false)
	
	# Hide drag preview and drop indicator
	drag_preview.visible = false
	drop_indicator.visible = false
	modulate.a = 1.0
	
	# Check if mouse is still over this slot after drag ends
	var mouse_pos = get_global_mouse_position()
	var rect = Rect2(global_position, size)
	var mouse_still_over = rect.has_point(mouse_pos)
	
	# Apply appropriate style based on mouse position
	if mouse_still_over and current_pet != null:
		slot_background.add_theme_stylebox_override("panel", hover_style)
	else:
		slot_background.add_theme_stylebox_override("panel", normal_style)
	
	# Check for valid drop target
	var drop_target = _find_drop_target()
	if drop_target != null and drop_target != self:
		_perform_drop(drop_target)

func _find_drop_target() -> Control:
	# Find all PetSlot nodes that could be drop targets
	var mouse_pos = get_global_mouse_position()
	var viewport = get_viewport()
	
	# Get all controls under the mouse
	var controls_under_mouse = []
	_find_controls_at_position(get_tree().current_scene, mouse_pos, controls_under_mouse)
	
	# Find the first PetSlot
	for control in controls_under_mouse:
		if control.has_method("_can_accept_drop") and control != self:
			return control
	
	return null

func _find_controls_at_position(node: Node, pos: Vector2, result: Array):
	if node is Control:
		var control = node as Control
		var rect = Rect2(control.global_position, control.size)
		if rect.has_point(pos):
			result.append(control)
	
	for child in node.get_children():
		_find_controls_at_position(child, pos, result)

func _can_accept_drop() -> bool:
	return true  # All slots can accept drops for now

func _perform_drop(target_slot):
	if target_slot.has_method("_handle_drop"):
		target_slot._handle_drop(current_pet, slot_index)

func _handle_drop(dropped_pet: Pet, source_slot_index: int):
	# This slot is receiving a pet
	if dropped_pet == null:
		return
	
	# Emit the appropriate signal based on slot type
	if is_team_slot:
		pet_dropped.emit(slot_index, dropped_pet)
	else:
		pet_dropped.emit(slot_index, dropped_pet)

# Drag and drop detection
func _can_drop_data(position: Vector2, data) -> bool:
	return data is Dictionary and data.has("pet")

func _drop_data(position: Vector2, data):
	if data.has("pet"):
		var dropped_pet = data["pet"] as Pet
		_handle_drop(dropped_pet, -1)

func _get_drag_data(position: Vector2):
	if current_pet == null:
		return null
	
	# Create drag data
	var drag_data = {
		"pet": current_pet,
		"source_slot": slot_index,
		"source_is_team": is_team_slot
	}
	
	# Set drag preview
	var preview = Control.new()
	var preview_texture = TextureRect.new()
	preview_texture.texture = current_pet.texture_card
	preview_texture.custom_minimum_size = Vector2(60, 60)
	preview_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.add_child(preview_texture)
	set_drag_preview(preview)
	
	return drag_data

# Visual feedback for drag over
func _notification(what):
	if what == NOTIFICATION_DRAG_BEGIN:
		_on_drag_begin()
	elif what == NOTIFICATION_DRAG_END:
		_on_drag_end()

func _on_drag_begin():
	drop_indicator.visible = false

func _on_drag_end():
	drop_indicator.visible = false
	slot_background.add_theme_stylebox_override("panel", normal_style)
