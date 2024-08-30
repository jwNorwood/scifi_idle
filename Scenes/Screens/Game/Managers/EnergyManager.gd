extends Node

@export var energy: float = 1:
	set = setEnergy,
	get = getEnergy

func getEnergy():
	return energy

func setEnergy(newValue: float):
	energy = newValue
	EventBus.new_energy_value.emit(newValue)

var timerDuration: float = 1:
	set = setTimer,
	get = getTimer
	
func getTimer():
	return timerDuration
	
func setTimer(newTime: float):
	if (newTime == timerDuration):
		return
	timerDuration = newTime
	$EnergyTimer.set_wait_time(newTime)
	
func updateEnergy(change: float):
	var newEnergy: float = energy + change
	energy = newEnergy

func _ready():
	$EnergyTimer.start()
	EventBus.on_energy_changed.connect(updateEnergy)
	EventBus.new_energy_value.emit(energy)

func _on_energy_timer_timeout():
	EventBus.on_energy_changed.emit(1)
