extends Node

# Player
var playerGold = 10
var playerTeam = []
var playerTeamInventory = []
var playerItems = []
var playerModifiers = []

func goldChange(value: int) -> int:
	var newValue = value + playerGold
	
	if (newValue >= 0):
		playerGold = newValue
		EventBus.player_gold_value_updated.emit(newValue)
		return playerGold
	else:
		return playerGold
	
func itemChange(item: Dictionary, add: bool) -> Array:
	if(add):
		playerItems.append(item)
		return playerItems
	else:
		# Filter Item
		print("item", item)
		return playerItems
		
func teamChange(newTeam: Array):
	playerTeam = newTeam
	
func inventoryTeamChange(newInvTeam: Array):
	playerTeamInventory = newInvTeam
	
func modifierAdd(newModifier: Dictionary):
	playerModifiers.append(newModifier)
	
func _ready():
	EventBus.player_gold_change.connect(goldChange)
