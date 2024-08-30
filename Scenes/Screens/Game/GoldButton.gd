extends Button

func _pressed():
	EventBus.on_gold_changed.emit(1)
