extends Button

func _pressed():
	EventBus.on_population_changed.emit(1)
