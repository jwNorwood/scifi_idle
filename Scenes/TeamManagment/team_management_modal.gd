extends Control

signal team_changed(new_team: Array[Pet])

@onready var active_team_slots: Container = %ActiveTeamSlots
@onready var inventory_slots: Container = %InventorySlots
@onready var background: ColorRect = $Background

var original_team: Array[Pet] = []
var current_team: Array[Pet] = []
var inventory_pets: Array[Pet] = []

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
		slot.pet_dropped.connect(_on_pet_dropped_to_team)
		slot.pet_removed.connect(_on_pet_removed_from_team)
		
		if i < current_team.size():
			slot.set_pet(current_team[i])
		
		active_team_slots.add_child(slot)

func _setup_inventory_slots():
	# Clear existing slots
	for child in inventory_slots.get_children():
		child.queue_free()
	
	# Create fixed number of inventory slots (filled and empty)
	for i in range(MAX_INVENTORY_SIZE):
		var slot = PET_SLOT_SCENE.instantiate()
		slot.slot_index = i
		slot.is_team_slot = false
		slot.pet_dropped.connect(_on_pet_dropped_to_inventory)
		slot.pet_removed.connect(_on_pet_removed_from_inventory)
		
		# Set pet if one exists at this index, otherwise leave empty
		if i < inventory_pets.size():
			slot.set_pet(inventory_pets[i])
		else:
			slot.set_pet(null)  # Empty slot
		
		inventory_slots.add_child(slot)

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
