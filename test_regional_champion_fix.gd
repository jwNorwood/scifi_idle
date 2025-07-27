extends Node

# Test script to verify Regional Champions always appear in final layer
func _ready():
	test_regional_champion_placement()

func test_regional_champion_placement():
	print("=== Testing Regional Champion Placement ===")
	
	var map_generator = OverworldMapGenerator.new()
	
	# Test multiple map generations
	for test_run in range(5):
		print("\n--- Test Run ", test_run + 1, " ---")
		
		# Generate a map
		var map_data = map_generator.generate_overworld_map()
		
		# Find the final layer (just before end node)
		var final_layer = map_generator.layers
		var final_layer_nodes = []
		var regional_champions_in_final = 0
		
		# Check all nodes in the generated map
		for encounter_data in map_data.encounters:
			if encounter_data.layer == final_layer:
				final_layer_nodes.append(encounter_data)
				if encounter_data.type == "REGIONAL_CHAMPION":
					regional_champions_in_final += 1
		
		print("Final layer (", final_layer, ") has ", final_layer_nodes.size(), " nodes")
		print("Regional Champions in final layer: ", regional_champions_in_final)
		
		# Verify all final layer nodes are Regional Champions
		var all_champions = true
		for node in final_layer_nodes:
			print("  - Node ", node.id, ": ", node.type)
			if node.type != "REGIONAL_CHAMPION":
				all_champions = false
		
		if all_champions and final_layer_nodes.size() > 0:
			print("✅ SUCCESS: All final layer encounters are Regional Champions!")
		else:
			print("❌ FAILED: Not all final layer encounters are Regional Champions!")
	
	print("\n=== Test Complete ===")
	get_tree().quit()
