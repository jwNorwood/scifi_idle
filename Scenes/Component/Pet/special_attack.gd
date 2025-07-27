extends State

@onready var timer = %SpecialAttackTimer
@onready var attack = %Attack

func enter() -> void:
	timer.start(parent.pet.speed / 2.0)  # Double attack speed
	super()
	
func exit() -> void:
	attack.enter()

func _on_state_timer_timeout():
	parent.specialAttack()
	timer.stop()
	
	if (!self.active):
		return
	exit()
