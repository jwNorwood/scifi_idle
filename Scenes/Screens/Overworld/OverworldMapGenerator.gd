extends Node
class_name OverworldMapGenerator

# Map configuration
@export var map_width: int = 800  # Total width of the map
@export var map_height: int = 600  # Total height of the map
@export var layers: int = 5  # Number of depth layers (excluding start/end)
@export var min_nodes_per_layer: int = 2
@export var max_nodes_per_layer: int = 4
@export var horizontal_spacing: int = 150  # Consistent horizontal spacing
@export var vertical_spacing: int = 120   # Consistent vertical spacing

# Graph structure
var map_data: Dictionary = {}
var node_positions: Dictionary = {}
var connections: Array[Dictionary] = []

enum encounters { WILD, TRAINER, MYSTERY, SHOP } 

signal map_generated(map_data: Dictionary)
signal node_positioned(node_id: int, position: Vector2)

func generate_map(num_layers: int, min_nodes: int, max_nodes: int, layer_height: int, h_spacing: int, _encounter_type_list: Array[String] = []) -> Dictionary:
	"""Generate a map with specified parameters - interface for external calls"""
	# Update internal parameters
	layers = num_layers
	min_nodes_per_layer = min_nodes
	max_nodes_per_layer = max_nodes
	vertical_spacing = layer_height
	horizontal_spacing = h_spacing
	
	# Generate and return the map
	return generate_overworld_map()

func generate_overworld_map() -> Dictionary:
	"""Generate a complete overworld map with consistent spacing"""
	_clear_previous_data()
	_generate_node_structure()
	_calculate_node_positions()
	_create_connections()
	
	# Format the data for external consumption
	var formatted_data = {
		"encounters": _format_encounters_data(),
		"connections": _format_connections_data()
	}
	
	map_generated.emit(formatted_data)
	return formatted_data

func _format_encounters_data() -> Array[Dictionary]:
	"""Format encounter data for external use"""
	var encounter_list: Array[Dictionary] = []
	
	for node_id in map_data.keys():
		var node = map_data[node_id]
		var encounter_data = {
			"id": node_id,
			"type": node["type"],
			"layer": node["layer"],
			"position": node_positions[node_id],
			"connections": node["children"]
		}
		encounter_list.append(encounter_data)
	
	return encounter_list

func _format_connections_data() -> Array[Dictionary]:
	"""Format connection data for external use"""
	var formatted_connections: Array[Dictionary] = []
	
	for connection in connections:
		formatted_connections.append({
			"from_id": connection["from"],
			"to_id": connection["to"],
			"start_pos": connection["start_pos"],
			"end_pos": connection["end_pos"]
		})
	
	return formatted_connections

func _clear_previous_data():
	"""Clear any previous map data"""
	map_data.clear()
	node_positions.clear()
	connections.clear()

func _generate_node_structure():
	"""Generate the basic node structure for the map"""
	var node_id = 0
	
	# Create start node
	map_data[node_id] = {
		"id": node_id,
		"type": "start",
		"layer": 0,
		"children": []
	}
	node_id += 1
	
	# Generate middle layers
	var previous_layer_nodes: Array[int] = [0]  # Start with the start node
	
	for layer in range(1, layers + 1):
		var nodes_in_layer = randi_range(min_nodes_per_layer, max_nodes_per_layer)
		var current_layer_nodes: Array[int] = []
		
		for node_index in range(nodes_in_layer):
			map_data[node_id] = {
				"id": node_id,
				"type": _get_random_encounter_type(),
				"layer": layer,
				"children": []
			}
			current_layer_nodes.append(node_id)
			node_id += 1
		
		# Connect previous layer to current layer
		_connect_layers(previous_layer_nodes, current_layer_nodes)
		previous_layer_nodes = current_layer_nodes
	
	# Create end node
	var end_id = node_id
	map_data[end_id] = {
		"id": end_id,
		"type": "end",
		"layer": layers + 1,
		"children": []
	}
	
	# Connect last layer to end node
	for node_id_in_last_layer in previous_layer_nodes:
		map_data[node_id_in_last_layer]["children"].append(end_id)

func _get_random_encounter_type() -> String:
	"""Get a random encounter type with weighted probabilities"""
	var rand = randf()
	if rand < 0.5:
		return "WILD"
	elif rand < 0.75:
		return "TRAINER"
	elif rand < 0.9:
		return "MYSTERY"
	else:
		return "SHOP"

func _connect_layers(previous_nodes: Array[int], current_nodes: Array[int]):
	"""Create connections between two layers ensuring every node is reachable"""
	# Clear any existing connections for these nodes
	for prev_node in previous_nodes:
		map_data[prev_node]["children"].clear()
	
	# Strategy 1: Direct connections for equal or fewer current nodes
	if current_nodes.size() <= previous_nodes.size():
		for i in range(current_nodes.size()):
			var prev_node = previous_nodes[i]
			map_data[prev_node]["children"].append(current_nodes[i])
		
		# Connect remaining previous nodes to random current nodes
		for i in range(current_nodes.size(), previous_nodes.size()):
			var prev_node = previous_nodes[i]
			var random_current = current_nodes[randi() % current_nodes.size()]
			if not map_data[prev_node]["children"].has(random_current):
				map_data[prev_node]["children"].append(random_current)
	
	# Strategy 2: Distribute connections for more current nodes
	else:
		# Ensure every current node gets at least one connection
		for i in range(current_nodes.size()):
			var prev_node = previous_nodes[i % previous_nodes.size()]
			map_data[prev_node]["children"].append(current_nodes[i])
		
		# Add smart additional connections to avoid too many overlaps
		for prev_node in previous_nodes:
			var current_connections = map_data[prev_node]["children"].size()
			var max_additional = min(1, current_nodes.size() - current_connections)  # Limit to 1 additional
			
			if max_additional > 0 and randf() < 0.4:  # 40% chance for additional connection
				var available_targets = []
				for current_node in current_nodes:
					if not map_data[prev_node]["children"].has(current_node):
						available_targets.append(current_node)
				
				if available_targets.size() > 0:
					var target = available_targets[randi() % available_targets.size()]
					map_data[prev_node]["children"].append(target)

func _calculate_node_positions():
	"""Calculate consistent positions for all nodes"""
	var layers_with_nodes = _group_nodes_by_layer()
	
	for layer in layers_with_nodes.keys():
		var nodes_in_layer = layers_with_nodes[layer]
		_position_layer_nodes(layer, nodes_in_layer)

func _group_nodes_by_layer() -> Dictionary:
	"""Group nodes by their layer for positioning"""
	var layers_with_nodes = {}
	
	for node_id in map_data.keys():
		var layer = map_data[node_id]["layer"]
		if not layers_with_nodes.has(layer):
			var new_layer_array: Array[int] = []
			layers_with_nodes[layer] = new_layer_array
		layers_with_nodes[layer].append(node_id)
	
	return layers_with_nodes

func _position_layer_nodes(layer: int, nodes: Array[int]):
	"""Position nodes in a specific layer with consistent spacing"""
	var x_position = (layer * horizontal_spacing) - (map_width / 2.0)
	
	var nodes_count = nodes.size()
	var total_layer_height = (nodes_count - 1) * vertical_spacing
	var start_y = -(total_layer_height / 2.0)
	
	for i in range(nodes_count):
		var node_id = nodes[i]
		var y_position = start_y + (i * vertical_spacing)
		
		var position = Vector2(x_position, y_position)
		node_positions[node_id] = position
		node_positioned.emit(node_id, position)

func _create_connections():
	"""Create connection data for drawing paths"""
	connections.clear()
	
	for node_id in map_data.keys():
		var node = map_data[node_id]
		var start_pos = node_positions[node_id]
		
		for child_id in node["children"]:
			if child_id in node_positions:
				var end_pos = node_positions[child_id]
				connections.append({
					"from": node_id,
					"to": child_id,
					"start_pos": start_pos,
					"end_pos": end_pos
				})

# Utility functions
func get_node_data(node_id: int) -> Dictionary:
	"""Get data for a specific node"""
	return map_data.get(node_id, {})

func get_node_position(node_id: int) -> Vector2:
	"""Get position for a specific node"""
	return node_positions.get(node_id, Vector2.ZERO)

func get_connections() -> Array[Dictionary]:
	"""Get all connection data for drawing paths"""
	return connections

func get_nodes_at_layer(layer: int) -> Array[int]:
	"""Get all nodes at a specific layer"""
	var nodes: Array[int] = []
	for node_id in map_data.keys():
		if map_data[node_id]["layer"] == layer:
			nodes.append(node_id)
	return nodes

func can_reach_node(from_id: int, to_id: int) -> bool:
	"""Check if one node can reach another (direct connection)"""
	return map_data.get(from_id, {}).get("children", []).has(to_id)

func get_start_node() -> int:
	"""Get the start node ID"""
	for node_id in map_data.keys():
		if map_data[node_id]["type"] == "start":
			return node_id
	return -1

func get_end_node() -> int:
	"""Get the end node ID"""
	for node_id in map_data.keys():
		if map_data[node_id]["type"] == "end":
			return node_id
	return -1
