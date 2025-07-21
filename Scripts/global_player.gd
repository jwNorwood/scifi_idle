extends Node

# Player
var playerGold = 10
var playerTeam = []
var playerTeamInventory = []
var playerItems = []
var playerModifiers = []
var playerExp: int = 0
var playerLevel = 1

func experienceToNextLevel(level: int) -> int:
	print("Calculating experience to next level for level: ", level)
	return 10

func experienceChange(value: int) -> int:
	var newValue = value + playerExp
	if (newValue >= 0):
		playerExp = newValue
		if (playerExp >= experienceToNextLevel(playerLevel)):
			playerLevel += 1
			EventBus.player_level_value_updated.emit(playerLevel)
			print("Player leveled up to level: ", playerLevel)
			return playerLevel
		EventBus.player_experience_value_updated.emit(newValue)
		return newValue
	else :
		return playerExp
	

func levelChange(value: int) -> int:
	var newValue = value + playerLevel
	if (newValue >= 0):
		playerLevel = newValue
		EventBus.player_level_value_updated.emit(newValue)
		# open the level up modal
		print("Player level changed to: ", newValue)
		return newValue
	else:
		return playerLevel	

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
	EventBus.player_experience_change.connect(experienceChange)
	EventBus.player_level_change.connect(levelChange)
	EventBus.player_team_change.connect(teamChange)
	EventBus.player_inventory_team_change.connect(inventoryTeamChange)
	EventBus.player_item_change.connect(itemChange)
	EventBus.player_modifier_add.connect(modifierAdd)
