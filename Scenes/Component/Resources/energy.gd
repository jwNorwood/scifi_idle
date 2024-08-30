extends HBoxContainer

@onready var energyLabel = %EnergyNumber

func setEnergy(newValue: float):
	energyLabel.text = str(newValue)

func _ready():
	EventBus.new_energy_value.connect(setEnergy)
