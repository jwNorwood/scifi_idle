extends HBoxContainer

@onready var currencyLabel = %CurrencyNumber

func setCurrency(newValue: float):
	currencyLabel.text = str(newValue)

func _ready():
	EventBus.new_currency_value.connect(setCurrency)
