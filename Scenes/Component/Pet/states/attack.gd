extends State

@onready var timer = $AttackTimer
@onready var specialAttack = %SpecialAttack
@onready var deadState = %Dead
@onready var victoryState = %Victory

func goNextState(next):
	if (next == "victory"):
		victoryState.enter()
		exit()
	if (next == "dead"):
		deadState.enter()
		exit()
	if (next == "special"):
		specialAttack.enter()
		exit()
	if (!self.active):
		return
	enter()

func enter() -> void:
	timer.start(parent.pet.speed)
	super()
	
func exit() -> void:
	super()

func _on_state_timer_timeout():
	timer.stop()
	var nextState = parent.attack()
	goNextState(nextState)
