extends Node

@onready var goldValue = %GoldValue

func goldChange(value: int):
	print("gold changed: ", value)
	goldValue.text = str(value)
	
func _ready():
	# player events
	EventBus.player_gold_value_updated.connect(goldChange)
	
	goldValue.text = str(GlobalPlayer.playerGold)
