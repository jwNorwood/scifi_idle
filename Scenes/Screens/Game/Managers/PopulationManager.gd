extends Node

@export var population: int = 1:
	set = setPopulation,
	get = getPopulation
	
func setPopulation(newValue):
	population = newValue
	EventBus.new_population_value.emit(newValue)
	
func getPopulation():
	return population

var timerDuration: float = 1:
	set = setTimer,
	get = getTimer

func setTimer(newTime: float):
	if (newTime == timerDuration):
		return
	timerDuration = newTime
	$PopulationTimer.set_wait_time(newTime)

func getTimer():
	return timerDuration

func updatePopulation(change: float):
	var newPopulation: float = population + change
	population = newPopulation

func updateTimer(change: float):
	var newTime = timerDuration + change
	setTimer(newTime)

func _ready():
	$PopulationTimer.start()
	EventBus.on_population_changed.connect(updatePopulation)
	EventBus.on_population_rate_changed.connect(updateTimer)

func _on_population_timer_timeout():
	EventBus.on_population_changed.emit(1)
