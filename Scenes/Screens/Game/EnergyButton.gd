extends Button

func _pressed():
	EventBus.on_energy_changed.emit(1)
