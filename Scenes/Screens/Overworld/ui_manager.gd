extends Node

@onready var goldValue = %GoldValue
@onready var expValue = 1

func goldChange(value: int):
	print("gold changed: ", value)
	goldValue.text = str(value)
	
func expChange(value: int):
	print("exp change: ", value)
	
func _ready():
	# player events
	EventBus.player_gold_value_updated.connect(goldChange)
	EventBus.player_experience_value_updated.connect(expChange)
	
	goldValue.text = str(GlobalPlayer.playerGold)
	expValue = GlobalPlayer.playerExp
