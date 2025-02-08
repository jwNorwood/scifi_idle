extends Button

func _pressed():
	EventBus.on_currency_changed.emit(1)
