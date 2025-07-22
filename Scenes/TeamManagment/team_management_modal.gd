extends Control

signal team_changed(new_team: Array[Pet])

@onready var active_team_slots: Container = %ActiveTeamSlots
@onready var inventory_slots: Container = %InventorySlots
@onready var background: ColorRect = $Background

var original_team: Array[Pet] = []
var current_team: Array[Pet] = []
var inventory_pets: Array[Pet] = []

# Drag and drop state
var is_dragging: bool = false
var dragged_pet: Pet = null
var drag_source_slot: Control = null
var drag_preview: Control = null

const MAX_TEAM_SIZE = 5
const MAX_INVENTORY_SIZE = 5  # Fixed inventory grid size
const PET_SLOT_SCENE = preload("res://Scenes/TeamManagment/PetSlot.tscn")

func _ready():
	# Hide the modal initially
	visible = false
	
	# Connect background click to close modal
	if background:
		background.gui_input.connect(_on_background_clicked)

func _exit_tree():
	# Ensure overworld content is unpaused when modal is removed
	_unpause_overworld_content()

func show_modal():
	# Load current team and inventory from GlobalPlayer
	original_team = GlobalPlayer.playerTeam.duplicate()
	current_team = GlobalPlayer.playerTeam.duplicate()
	inventory_pets = GlobalPlayer.playerTeamInventory.duplicate()
	
	_setup_team_slots()
	_setup_inventory_slots()
	
	# Pause overworld content
	_pause_overworld_content()
	
	visible = true

func _setup_team_slots():
	# Clear existing slots
	for child in active_team_slots.get_children():
		child.queue_free()
	
	# Create slots for active team (up to MAX_TEAM_SIZE)
	for i in range(MAX_TEAM_SIZE):
		var slot = PET_SLOT_SCENE.instantiate()
		slot.slot_index = i
		slot.is_team_slot = true
		
		# Connect to centralized drag system
		slot.drag_started.connect(_on_slot_drag_started)
		slot.pet_removed.connect(_on_pet_removed_from_team)
		
		if i < current_team.size():
			slot.set_pet(current_team[i])
		
		active_team_slots.add_child(slot)

func _setup_inventory_slots():
	# Clear existing slots
	for child in inventory_slots.get_children():
		child.queue_free()
	
	# Create exactly MAX_INVENTORY_SIZE slots (5 slots)
	for i in range(MAX_INVENTORY_SIZE):
		var slot = PET_SLOT_SCENE.instantiate()
		slot.slot_index = i
		slot.is_team_slot = false
		
		# Set pet if one exists at this index
		if i < inventory_pets.size():
			slot.set_pet(inventory_pets[i])
		
		# Connect to centralized drag system
		slot.drag_started.connect(_on_slot_drag_started)
		slot.pet_removed.connect(_on_pet_removed_from_inventory)
		
		inventory_slots.add_child(slot)

# Handle drag started from any slot
func _on_slot_drag_started(pet: Pet, slot: Control):
	start_pet_drag(pet, slot)

func _on_pet_dropped_to_team(slot_index: int, pet: Pet):
	# Handle dropping pet to team slot
	if slot_index < 0 or slot_index >= MAX_TEAM_SIZE:
		return
	
	# Find where the pet currently is (team or inventory)
	var source_team_index = current_team.find(pet)
	var source_inv_index = inventory_pets.find(pet)
	
	# If there's already a pet in the target slot, move it to inventory
	if slot_index < current_team.size() and current_team[slot_index] != null:
		var displaced_pet = current_team[slot_index]
		# Only add to inventory if it's not the same pet being moved
		if displaced_pet != pet:
			inventory_pets.append(displaced_pet)
	
	# Remove pet from its current location
	if source_team_index != -1:
		# Pet came from team - remove from original position
		current_team[source_team_index] = null
		# Clean up null entries
		while current_team.size() > 0 and current_team[current_team.size() - 1] == null:
			current_team.remove_at(current_team.size() - 1)
	elif source_inv_index != -1:
		# Pet came from inventory - remove from inventory
		inventory_pets.remove_at(source_inv_index)
	
	# Add the pet to the target team slot
	if slot_index >= current_team.size():
		current_team.resize(slot_index + 1)
	
	current_team[slot_index] = pet
	
	# Refresh displays
	_setup_team_slots()
	_setup_inventory_slots()

func _on_pet_removed_from_team(slot_index: int):
	# Move pet from team to inventory
	if slot_index < 0 or slot_index >= current_team.size():
		return
	
	var pet = current_team[slot_index]
	if pet != null:
		inventory_pets.append(pet)
		current_team.remove_at(slot_index)
		
		# Refresh displays
		_setup_team_slots()
		_setup_inventory_slots()

func _on_pet_dropped_to_inventory(slot_index: int, pet: Pet):
	# Handle dropping pet to inventory
	if slot_index < 0 or slot_index >= MAX_INVENTORY_SIZE:
		return
	
	# Find where the pet currently is (team or inventory)
	var source_team_index = current_team.find(pet)
	var source_inv_index = inventory_pets.find(pet)
	
	# Handle what's currently in the target slot
	var displaced_pet = null
	if slot_index < inventory_pets.size():
		displaced_pet = inventory_pets[slot_index]
	
	# Remove pet from its current location
	if source_team_index != -1:
		# Pet came from team - remove from original position
		current_team[source_team_index] = null
		# Clean up null entries from end of team
		while current_team.size() > 0 and current_team[current_team.size() - 1] == null:
			current_team.remove_at(current_team.size() - 1)
	elif source_inv_index != -1:
		# Pet came from inventory - remove from original position
		inventory_pets.remove_at(source_inv_index)
		# Adjust slot_index if it was after the removed item
		if source_inv_index < slot_index:
			slot_index -= 1
	
	# Place the pet in the target slot
	if slot_index >= inventory_pets.size():
		# Extend inventory to include this slot
		inventory_pets.resize(slot_index + 1)
	
	# If there was a displaced pet and it's not the same pet, find a new spot for it
	if displaced_pet != null and displaced_pet != pet:
		# Find first empty inventory slot or append to end
		var empty_slot_found = false
		for i in range(inventory_pets.size()):
			if inventory_pets[i] == null:
				inventory_pets[i] = displaced_pet
				empty_slot_found = true
				break
		if not empty_slot_found:
			inventory_pets.append(displaced_pet)
	
	inventory_pets[slot_index] = pet
	
	# Clean up any null entries in the middle of inventory
	for i in range(inventory_pets.size() - 1, -1, -1):
		if inventory_pets[i] == null:
			inventory_pets.remove_at(i)
	
	# Refresh displays
	_setup_team_slots()
	_setup_inventory_slots()

func _on_pet_removed_from_inventory(slot_index: int):
	# Remove pet from inventory (this would delete it completely)
	# For now, we'll just move it back to team if there's space
	if slot_index < 0 or slot_index >= inventory_pets.size():
		return
	
	var pet = inventory_pets[slot_index]
	if current_team.size() < MAX_TEAM_SIZE:
		current_team.append(pet)
		inventory_pets.remove_at(slot_index)
		
		# Refresh displays
		_setup_team_slots()
		_setup_inventory_slots()

func _on_save_button_pressed():
	# Save changes to GlobalPlayer
	GlobalPlayer.playerTeam = current_team.duplicate()
	GlobalPlayer.playerTeamInventory = inventory_pets.duplicate()
	
	# Emit signal for other systems that might need to update
	team_changed.emit(current_team)
	
	# Update global events
	EventBus.player_team_value_updated.emit(current_team)
	EventBus.player_inventory_team_value_updated.emit(inventory_pets)
	
	# Unpause overworld content
	_unpause_overworld_content()
	
	visible = false

func _on_cancel_button_pressed():
	# Restore original values without saving
	current_team = original_team.duplicate()
	inventory_pets = GlobalPlayer.playerTeamInventory.duplicate()
	
	# Unpause overworld content
	_unpause_overworld_content()
	
	visible = false

func _on_close_button_pressed():
	_on_cancel_button_pressed()

func _on_background_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Close modal when clicking on the background
		_on_cancel_button_pressed()

func _pause_overworld_content():
	# Get the overworld content node and pause it
	var overworld_content = get_tree().get_first_node_in_group("overworld_content")
	if not overworld_content:
		# Fallback: try to find by unique name
		overworld_content = get_node_or_null("../../OverworldContent")
	
	if overworld_content:
		overworld_content.visible = false
		overworld_content.process_mode = Node.PROCESS_MODE_DISABLED
		print("Overworld content paused")
	else:
		print("Warning: Could not find overworld content to pause")

func _unpause_overworld_content():
	# Get the overworld content node and unpause it
	var overworld_content = get_tree().get_first_node_in_group("overworld_content")
	if not overworld_content:
		# Fallback: try to find by unique name
		overworld_content = get_node_or_null("../../OverworldContent")
	
	if overworld_content:
		overworld_content.visible = true
		overworld_content.process_mode = Node.PROCESS_MODE_INHERIT
		print("Overworld content unpaused")
	else:
		print("Warning: Could not find overworld content to unpause")

# Centralized drag and drop management
func start_pet_drag(pet: Pet, source_slot: Control):
	if is_dragging:
		return
	
	is_dragging = true
	dragged_pet = pet
	drag_source_slot = source_slot
	
	# Create drag preview
	_create_drag_preview(pet)
	
	# Update all slots for drag state
	_update_all_slots_for_drag_start()
	
	# Start processing for drag updates
	set_process(true)

func _create_drag_preview(pet: Pet):
	if drag_preview:
		drag_preview.queue_free()
	
	drag_preview = Control.new()
	drag_preview.z_index = 1000  # Ensure it's on top
	
	var preview_texture = TextureRect.new()
	preview_texture.texture = pet.texture_card
	preview_texture.custom_minimum_size = Vector2(60, 60)
	preview_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview_texture.modulate.a = 0.8
	
	drag_preview.add_child(preview_texture)
	add_child(drag_preview)
	
	# Position at mouse
	drag_preview.global_position = get_global_mouse_position() - Vector2(30, 30)

func _process(_delta):
	if is_dragging:
		_update_drag()

func _update_drag():
	if not drag_preview:
		return
	
	# Update preview position
	drag_preview.global_position = get_global_mouse_position() - Vector2(30, 30)
	
	# Update hover effects on all slots
	_update_all_slots_hover_effects()

func end_pet_drag():
	if not is_dragging:
		return
	
	# Find drop target
	var drop_target = _find_drop_target_at_mouse()
	
	# Perform drop if valid target found
	if drop_target and drop_target != drag_source_slot:
		_perform_pet_drop(drop_target)
	
	# Clean up drag state
	_cleanup_drag_state()

func _find_drop_target_at_mouse() -> Control:
	# Check all team slots
	for slot in active_team_slots.get_children():
		if slot.has_method("is_mouse_over") and slot.is_mouse_over():
			return slot
	
	# Check all inventory slots
	for slot in inventory_slots.get_children():
		if slot.has_method("is_mouse_over") and slot.is_mouse_over():
			return slot
	
	return null

func _perform_pet_drop(target_slot: Control):
	var target_index = target_slot.slot_index
	var target_is_team = target_slot.is_team_slot
	
	if target_is_team:
		_on_pet_dropped_to_team(target_index, dragged_pet)
	else:
		_on_pet_dropped_to_inventory(target_index, dragged_pet)

func _update_all_slots_for_drag_start():
	# Update source slot appearance
	if drag_source_slot and drag_source_slot.has_method("set_drag_source_appearance"):
		drag_source_slot.set_drag_source_appearance()
	
	# Update all other slots for potential drop targets
	_update_all_slots_hover_effects()

func _update_all_slots_hover_effects():
	# Update team slots
	for slot in active_team_slots.get_children():
		if slot.has_method("update_drag_hover"):
			var is_over = slot.is_mouse_over() if slot.has_method("is_mouse_over") else false
			slot.update_drag_hover(is_over)
	
	# Update inventory slots
	for slot in inventory_slots.get_children():
		if slot.has_method("update_drag_hover"):
			var is_over = slot.is_mouse_over() if slot.has_method("is_mouse_over") else false
			slot.update_drag_hover(is_over)

func _cleanup_drag_state():
	is_dragging = false
	dragged_pet = null
	drag_source_slot = null
	
	# Remove drag preview
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null
	
	# Reset all slot appearances
	_reset_all_slot_appearances()
	
	# Stop processing
	set_process(false)

func _reset_all_slot_appearances():
	# Reset team slots
	for slot in active_team_slots.get_children():
		if slot.has_method("reset_drag_appearance"):
			slot.reset_drag_appearance()
	
	# Reset inventory slots
	for slot in inventory_slots.get_children():
		if slot.has_method("reset_drag_appearance"):
			slot.reset_drag_appearance()

# Handle input for drag end detection
func _input(event):
	if is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			end_pet_drag()
