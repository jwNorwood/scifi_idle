extends State

@onready var timer = $WalkTimer
@onready var idle = $"../Idle"

func randomMovement() -> float:
	var posOrNeg = randi_range(0, 1)
	var value = randf() * 10
	if (posOrNeg == 1):
		return value
	return value * -1
	
func enter() -> void:
	timer.start(3)
	print("Walks: Start the timer")
	super()
	if (!parent):
		return
	parent.velocity.x = randomMovement()
	parent.velocity.y = randomMovement()
	
func processPhysics(delta) -> State:
	parent.move_and_slide()
	return null

func exit() -> void:
	super()
	idle.enter()

func _on_state_timer_timeout():
	print("Walk: timer over")
	if (!self.active):
		return
	exit()
