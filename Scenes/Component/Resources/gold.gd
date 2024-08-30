extends HBoxContainer

@onready var goldLabel = %GoldNumber

func setGold(newValue: float):
	goldLabel.text = str(newValue)

func _ready():
	EventBus.new_gold_value.connect(setGold)
