extends Node

@export var currency: float = 1:
	set = setCurrency,
	get = getCurrency
	
var timerDuration: float = 1:
	set = setTimer,
	get = getTimer
	
func updateCurrency(change: float):
	var newCurrency: float = currency + change
	currency = newCurrency
	
func setCurrency(newValue: float):
	currency = newValue
	EventBus.new_currency_value.emit(newValue)

func getCurrency():
	return currency
	
func setTimer(newTime: float):
	if (newTime == timerDuration):
		return
	timerDuration = newTime
	$CurrencyTimer.set_wait_time(newTime)

func getTimer():
	return timerDuration

func updateTimer(change: float):
	var newValue = timerDuration + change
	setTimer(newValue)

func _ready():
	$CurrencyTimer.start()
	EventBus.on_currency_changed.connect(updateCurrency)
	EventBus.on_currency_rate_changed.connect(updateTimer)

func _on_currency_timer_timeout():
	EventBus.on_currency_changed.emit(1)
