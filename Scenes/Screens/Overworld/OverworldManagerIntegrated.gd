extends Node

# Internal state
var current_encounter: Encounter
var player_moving: bool = false
var is_in_encounter: bool = false
var initial_move: bool = true
var spawn_location: Vector2
var map_generator: OverworldMapGenerator

# Exports for customization
@export var layers: int = 5
@export var min_nodes_per_layer: int = 2
@export var max_nodes_per_layer: int = 4
@export var layer_height: int = 120
@export var horizontal_spacing: int = 150
@export var encounter_types: Array[String] = ["WILD", "TRAINER", "MYSTERY", "SHOP", "REGIONAL_CHAMPION"]

# Scene references (using unique names from existing scene)
@onready var map: Control = %Map
@onready var modal = %ModalEncounterInfo
@onready var player: OverworldPlayer = %Player
@onready var activeEncounter = %ActiveEncounter
@onready var overworldContent = %OverworldContent

func _ready():
	# Initialize map generator
	map_generator = OverworldMapGenerator.new()
	
	# Player event connections
	player.travel_finished.connect(_on_player_finished_travel)
	
	# Generate and display the overworld map
	generate_overworld()

func generate_overworld():
	# Clear existing map
	for child in map.get_children():
		child.queue_free()
	
	# Generate the map structure
	var map_data = map_generator.generate_map(
		layers, 
		min_nodes_per_layer, 
		max_nodes_per_layer, 
		layer_height, 
		horizontal_spacing,
		encounter_types
	)
	
	# Create encounters from map data
	for node_data in map_data.encounters:
		var encounter = create_encounter_from_data(node_data)
		map.add_child(encounter)
	
	# Set spawn location to first encounter
	if map.get_child_count() > 0:
		var start_encounter = find_encounter_by_id(0)  # Start node should have ID 0
		if start_encounter:
			spawn_location = start_encounter.global_position
			current_encounter = start_encounter
	
	# Draw connections with improved path system
	draw_connections(map_data.connections)

func create_encounter_from_data(node_data: Dictionary) -> Encounter:
	# Convert string type to enum value for compatibility
	var encounter_type
	match node_data.type:
		"WILD":
			encounter_type = Encounter.encounters.WILD
		"TRAINER":
			encounter_type = Encounter.encounters.TRAINER
		"MYSTERY":
			encounter_type = Encounter.encounters.MYSTERY
		"SHOP":
			encounter_type = Encounter.encounters.SHOP
		"REGIONAL_CHAMPION":
			encounter_type = Encounter.encounters.REGIONAL_CHAMPION
		_:
			encounter_type = Encounter.encounters.WILD
	
	# Convert connections to the format expected by Encounter class
	var child_nodes = []
	for connection_id in node_data.connections:
		child_nodes.append({"id": connection_id})
	
	var encounter = Encounter.create(
		node_data.id,
		node_data.layer, 
		child_nodes,
		encounter_type
	)
	
	# Set position
	encounter.position = node_data.position
	
	# Connect signals
	encounter.encounter_selected.connect(_on_encounter_selected)
	encounter.encounter_hovered.connect(_on_encounter_hovered)
	
	return encounter

func draw_connections(connections: Array[Dictionary]):
	# Create a container for all path lines
	var paths_container = Node2D.new()
	paths_container.name = "PathsContainer"
	paths_container.z_index = -1  # Behind encounters
	map.add_child(paths_container)
	
	# Group connections by their from_id to handle multiple connections better
	var grouped_connections = {}
	for connection in connections:
		var from_id = connection.from_id
		if not grouped_connections.has(from_id):
			grouped_connections[from_id] = []
		grouped_connections[from_id].append(connection)
	
	# Create curved paths for each group of connections
	for from_id in grouped_connections.keys():
		var from_encounter = find_encounter_by_id(from_id)
		if not from_encounter:
			continue
			
		var connection_group = grouped_connections[from_id]
		_draw_connection_group(paths_container, from_encounter, connection_group)

func _draw_connection_group(container: Node2D, from_encounter: Encounter, connections: Array):
	"""Draw a group of connections from one encounter with proper spacing"""
	var from_pos = from_encounter.position
	var connection_count = connections.size()
	
	for i in range(connection_count):
		var connection = connections[i]
		var to_encounter = find_encounter_by_id(connection.to_id)
		if not to_encounter:
			continue
			
		var to_pos = to_encounter.position
		
		# Create curved path to avoid overlaps
		var path_line = Line2D.new()
		path_line.name = "Path_%d_to_%d" % [connection.from_id, connection.to_id]
		
		# Calculate curve points to spread out multiple connections
		var curve_points = _calculate_curved_path(from_pos, to_pos, i, connection_count)
		
		for point in curve_points:
			path_line.add_point(point)
		
		# Style the path
		path_line.width = 6.0
		path_line.default_color = Color(0.8, 0.8, 0.8, 0.7)  # Semi-transparent white
		path_line.joint_mode = Line2D.LINE_JOINT_ROUND
		path_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		path_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		
		container.add_child(path_line)

func _calculate_curved_path(from_pos: Vector2, to_pos: Vector2, connection_index: int, total_connections: int) -> Array[Vector2]:
	"""Calculate points for a curved path between two positions"""
	var points: Array[Vector2] = []
	
	# Base curve calculation
	var direction = (to_pos - from_pos).normalized()
	var distance = from_pos.distance_to(to_pos)
	var midpoint = from_pos + (to_pos - from_pos) * 0.5
	
	# Calculate offset for multiple connections
	var offset_amount = 0.0
	if total_connections > 1:
		# Spread connections vertically if going horizontally, horizontally if going vertically
		var perpendicular = Vector2(-direction.y, direction.x)
		var max_offset = min(distance * 0.2, 40.0)  # Max 20% of distance or 40 pixels
		
		# Calculate offset for this specific connection
		if total_connections == 2:
			offset_amount = max_offset * (connection_index * 2 - 1) * 0.5  # -0.5 or +0.5
		else:
			# For 3+ connections, spread them out more evenly
			var step = max_offset * 2 / (total_connections - 1)
			offset_amount = -max_offset + (connection_index * step)
		
		midpoint += perpendicular * offset_amount
	
	# Create smooth curve with multiple points
	var curve_segments = 8
	for i in range(curve_segments + 1):
		var t = float(i) / float(curve_segments)
		var point: Vector2
		
		if total_connections == 1 or abs(offset_amount) < 5.0:
			# Simple linear interpolation for single connections or small offsets
			point = from_pos.lerp(to_pos, t)
		else:
			# Quadratic Bezier curve for multiple connections
			point = _bezier_quadratic(from_pos, midpoint, to_pos, t)
		
		points.append(point)
	
	return points

func _bezier_quadratic(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	"""Calculate point on quadratic Bezier curve"""
	var one_minus_t = 1.0 - t
	return (one_minus_t * one_minus_t * p0) + (2.0 * one_minus_t * t * p1) + (t * t * p2)

func find_encounter_by_id(id: int) -> Encounter:
	for child in map.get_children():
		if child is Encounter and child.id == id:
			return child
	return null

func _process(_delta):
	# Handle encounter state transitions
	if is_in_encounter and activeEncounter.get_child_count() == 0:
		overworldContent.show()
		is_in_encounter = false
	
	# Handle initial positioning
	if initial_move and spawn_location != Vector2.ZERO:
		player.global_position = spawn_location
		initial_move = false

func _on_player_finished_travel():
	player_moving = false
	overworldContent.hide()
	is_in_encounter = true
	
	# Start the encounter
	if current_encounter:
		current_encounter.enterEncounter(activeEncounter)

func _on_encounter_selected(encounter: Encounter):
	print("Selected encounter: ", encounter.id)
	
	if player_moving:
		return
	
	# Check if this encounter is reachable from current position
	if not current_encounter or not current_encounter.hasChildNode(encounter.id):
		print("Encounter not reachable!")
		return
	
	# Show encounter info modal
	modal.setTitle("Encounter " + str(encounter.id))
	modal.setDescription(get_encounter_description(encounter))
	
	# Move player
	player_moving = true
	player.travelToEncounter(encounter.id, encounter.global_position)
	current_encounter = encounter

func _on_encounter_hovered(encounter_id: int):
	print("Hovered encounter: ", encounter_id)

func get_encounter_description(encounter: Encounter) -> String:
	match encounter.nodeType:
		Encounter.encounters.WILD:
			return "A wild creature encounter awaits!"
		Encounter.encounters.TRAINER:
			return "A trainer wants to battle!"
		Encounter.encounters.MYSTERY:
			return "A mysterious event unfolds..."
		Encounter.encounters.SHOP:
			return "A traveling merchant offers their wares."
		Encounter.encounters.REGIONAL_CHAMPION:
			return "A Regional Champion with a powerful team of 5 pets stands ready to test your skills!"
		_:
			return "An unknown encounter."

# Regenerate the map (useful for testing or map variations)
func regenerate_map():
	generate_overworld()

# Debug function to test different map layouts
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:  # Press R to regenerate map
			print("Regenerating overworld map...")
			regenerate_map()
