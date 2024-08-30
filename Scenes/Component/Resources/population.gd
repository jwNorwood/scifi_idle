extends HBoxContainer

@onready var populationLabel = %PopulationNumber

func setPopulation(newValue: float):
	populationLabel.text = str(newValue)

func _ready():
	EventBus.new_population_value.connect(setPopulation)
