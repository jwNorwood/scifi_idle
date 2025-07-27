extends Node

# Player Events
signal player_gold_change(value: int)
signal player_experience_change(value: int)
signal player_level_change(value: int)
signal player_item_change(item: Dictionary, add: bool)
signal player_team_change(team: Array)
signal player_inventory_team_change(team: Array)
signal player_modifier_add(modifier: Dictionary)

signal player_gold_value_updated(value: int)
signal player_experience_value_updated(value: int)
signal player_level_value_updated(value: int)
signal player_items_updated(items: Array)
signal player_team_value_updated(team: Array)
signal player_inventory_team_value_updated(team: Array)
signal player_modifiers_value_updated(modifiers: Array)

# Map Events
signal map_regeneration_requested()

# Settings
