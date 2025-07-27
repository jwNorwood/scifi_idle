extends Node

# Map generation and display
var map_generator
@onready var map_container = %Map
@onready var player: OverworldPlayer = %Player
@onready var modal = %ModalEncounterInfo
@onready var activeEncounter = %ActiveEncounter
@onready var overworldContent = %OverworldContent

# Game state
var current_encounter: Encounter
var player_moving: bool = false
var is_in_encounter: bool = false
var initial_move: bool = true
var spawn_location: Vector2

# Map configuration
@export var map_layers: int = 5
@export var min_nodes_per_layer: int = 2
@export var max_nodes_per_layer: int = 4

# Node management
var encounter_nodes: Dictionary = {}  # node_id -> Encounter instance
var map_data: Dictionary = {}

enum encounters { WILD, TRAINER, MYSTERY, SHOP, REGIONAL_CHAMPION }

func _ready():
	_setup_map_generator()
	_generate_and_display_map()
	_setup_player()
	
	# Connect to map regeneration event
	EventBus.map_regeneration_requested.connect(_on_map_regeneration_requested)

func _input(event):
	"""Handle input for testing"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				print("Regenerating map...")
				regenerate_map()
			KEY_P:
				print_map_structure()
			KEY_H:
				highlight_reachable_nodes()

func _setup_map_generator():
	"""Configure the map generator"""
	map_generator = load("res://Scenes/Screens/Overworld/OverworldMapGenerator.gd").new()
	add_child(map_generator)
	map_generator.layers = map_layers
	map_generator.min_nodes_per_layer = min_nodes_per_layer
	map_generator.max_nodes_per_layer = max_nodes_per_layer
	
	# Connect signals
	map_generator.map_generated.connect(_on_map_generated)
	map_generator.node_positioned.connect(_on_node_positioned)

func _generate_and_display_map():
	"""Generate the map and create visual nodes"""
	map_data = map_generator.generate_overworld_map()
	_create_encounter_nodes()

func _on_map_generated(generated_map_data: Dictionary):
	"""Handle map generation completion"""
	print("Map generated with ", generated_map_data.size(), " nodes")

func _on_node_positioned(_node_id: int, _position: Vector2):
	"""Handle node positioning"""
	# This can be used for animation or debugging
	pass

func _create_encounter_nodes():
	"""Create visual encounter nodes from map data"""
	for node_id in map_data.keys():
		var node_data = map_data[node_id]
		var encounter_node = _create_encounter_instance(node_data)
		
		# Position the node
		var position = map_generator.get_node_position(node_id)
		encounter_node.global_position = position
		
		# Store reference
		encounter_nodes[node_id] = encounter_node
		
		# Add to scene
		map_container.add_child(encounter_node)

func _create_encounter_instance(node_data: Dictionary) -> Encounter:
	"""Create an Encounter instance from node data"""
	var encounter_type = _convert_string_to_enum(node_data["type"])
	var children_data = []
	
	# Convert children IDs to the format expected by Encounter
	for child_id in node_data["children"]:
		children_data.append({"id": child_id})
	
	var encounter = Encounter.create(
		node_data["id"],
		node_data["layer"],
		children_data,
		encounter_type
	)
	
	# Connect signals
	encounter.encounter_selected.connect(_on_encounter_selected)
	encounter.encounter_hovered.connect(_on_encounter_hovered)
	
	return encounter

func _convert_string_to_enum(encounter_type: String) -> int:
	"""Convert string encounter type to enum value"""
	match encounter_type.to_upper():
		"WILD":
			return encounters.WILD
		"TRAINER":
			return encounters.TRAINER
		"MYSTERY":
			return encounters.MYSTERY
		"SHOP":
			return encounters.SHOP
		"REGIONAL_CHAMPION":
			return encounters.REGIONAL_CHAMPION
		"START", "END":
			return encounters.WILD  # Default for special nodes
		_:
			return encounters.WILD

func _setup_player():
	"""Setup player starting position and connections"""
	player.travel_finished.connect(_on_player_finished_travel)
	
	# Position player at start node
	var start_node_id = map_generator.get_start_node()
	if start_node_id >= 0 and encounter_nodes.has(start_node_id):
		current_encounter = encounter_nodes[start_node_id]
		spawn_location = current_encounter.global_position
		player.global_position = spawn_location

func _on_encounter_selected(encounter: Encounter):
	"""Handle encounter selection"""
	print("Selected encounter: ", encounter.id)
	var current_id = current_encounter.id if current_encounter else -1
	print("Current encounter: ", current_id)
	
	if player_moving:
		return
	
	# Check if this encounter is reachable from current position
	if not _can_move_to_encounter(encounter):
		print("Cannot reach encounter ", encounter.id, " from current position")
		return
	
	# Setup movement
	_start_movement_to_encounter(encounter)

func _can_move_to_encounter(target_encounter: Encounter) -> bool:
	"""Check if player can move to the target encounter"""
	if not current_encounter:
		return false
	
	return map_generator.can_reach_node(current_encounter.id, target_encounter.id)

func _start_movement_to_encounter(target_encounter: Encounter):
	"""Start player movement to target encounter"""
	modal.setTitle("Moving to Encounter " + str(target_encounter.id))
	modal.setDescription("Traveling to new location...")
	
	initial_move = false
	player_moving = true
	player.travelToEncounter(target_encounter.id, target_encounter.global_position)
	current_encounter = target_encounter

func _on_encounter_hovered(encounter_id: int):
	"""Handle encounter hover"""
	print("Hovered encounter: ", encounter_id)
	
	# Could show preview info here
	var node_data = map_data.get(encounter_id, {})
	var _encounter_type = node_data.get("type", "unknown")
	# modal.setTitle(encounter_type.capitalize() + " Encounter")

func _on_player_finished_travel():
	"""Handle player finishing travel"""
	player_moving = false
	overworldContent.hide()
	is_in_encounter = true
	
	# Start the encounter
	if current_encounter:
		current_encounter.enterEncounter(activeEncounter)

func _process(_delta):
	"""Handle per-frame updates"""
	# Check if encounter is finished
	if is_in_encounter and activeEncounter.get_child_count() == 0:
		overworldContent.show()
		is_in_encounter = false
	
	# Handle initial positioning
	if initial_move and spawn_location != Vector2.ZERO:
		player.global_position = spawn_location

# Utility functions
func get_current_encounter() -> Encounter:
	"""Get the current encounter node"""
	return current_encounter

func get_reachable_encounters() -> Array[Encounter]:
	"""Get all encounters reachable from current position"""
	var reachable = []
	
	if not current_encounter:
		return reachable
	
	var current_node_data = map_data.get(current_encounter.id, {})
	var children_ids = current_node_data.get("children", [])
	
	for child_id in children_ids:
		if encounter_nodes.has(child_id):
			reachable.append(encounter_nodes[child_id])
	
	return reachable

func regenerate_map():
	"""Regenerate the entire map (useful for testing)"""
	# Clear existing nodes
	for encounter in encounter_nodes.values():
		encounter.queue_free()
	encounter_nodes.clear()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Generate new map
	_generate_and_display_map()
	_setup_player()

func _on_map_regeneration_requested():
	"""Handle map regeneration request from EventBus (e.g., after defeating Regional Champion)"""
	print("Received map regeneration request - generating new area!")
	regenerate_map()

# Debug functions
func print_map_structure():
	"""Debug function to print map structure"""
	print("=== MAP STRUCTURE ===")
	for node_id in map_data.keys():
		var node = map_data[node_id]
		print("Node ", node_id, ": Type=", node["type"], ", Layer=", node["layer"], ", Children=", node["children"])

func highlight_reachable_nodes():
	"""Debug function to highlight reachable nodes"""
	var reachable = get_reachable_encounters()
	print("Reachable encounters from current position: ")
	for encounter in reachable:
		print("  - Encounter ", encounter.id)
