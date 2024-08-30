extends Node

@export var gold: float = 1:
	set = setGold,
	get = getGold

func setGold(newValue: float):
	gold = newValue
	EventBus.new_gold_value.emit(newValue)

func getGold():
	return gold

var tickAmount: float = 1:
	set = setTick,
	get = getTick

func setTick(newValue):
	tickAmount = newValue

func getTick():
	return tickAmount

var timerDuration: float = 1:
	set = setTimer,
	get = getTimer

func setTimer(newTime: float):
	if (newTime == timerDuration):
		return
	timerDuration = newTime
	$GoldTimer.set_wait_time(newTime)

func getTimer():
	return timerDuration
	
func updateTimer(change: float):
	var newValue = timerDuration + change
	setTimer(newValue)

func updateGold(change: float):
	var newGold: float = gold + change
	gold = newGold

func _ready():
	EventBus.on_gold_changed.connect(updateGold)
	EventBus.on_gold_rate_changed.connect(updateTimer)
	$GoldTimer.start()

func _on_gold_timer_timeout():
	EventBus.on_gold_changed.emit(tickAmount)
