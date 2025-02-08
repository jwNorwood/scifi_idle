extends State

@onready var timer = $IdleTimer
@onready var walk = $"../Walk"

# I could have a status

func enter() -> void:
	timer.start(3)
	print("Idle: start the timer")
	super()
	if (!parent):
		return
	parent.velocity.x = 0
	parent.velocity.y = 0
	
func exit() -> void:
	print("enter walk")
	walk.enter()
	
func processPhysics(delta) -> State:
	parent.move_and_slide()
	return null

func _on_state_timer_timeout():
	print("Idle: timer over")
	timer.stop()
	if (!self.active):
		return
	exit()
