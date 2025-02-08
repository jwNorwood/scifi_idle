extends Container

@onready var stateMachine = $StateMachine
@onready var manaBar = %ManaBar
@onready var sprite = %Sprite

@export var pet: Resource

var parent

var mana: int = 10:
	set = setMana

func setMana(newValue):
	var maxMana = pet.mana_max
	if (newValue >= maxMana):
		mana = maxMana
		manaBar.value = maxMana
		return true
	mana = newValue
	manaBar.value = newValue
	return false

func attack():
	if (parent.health <= 0):
		return "dead"
	var deadTarget = parent.doDamage(pet.attack)
	if (deadTarget):
		return "victory"
	var nextAttackSpecial = setMana(pet.mana_attack + mana)
	if (nextAttackSpecial):
		return "special"
	return "attack"
	
func specialAttack():
	print("Special Attack: ", pet)
	if (pet.active_special_attack.has_method("trigger_attack")):
		pet.active_special_attack.trigger_attack(parent)
	assist()
	mana = 0
	manaBar.value = 0
	
func assist():
	print("Assist Attack")

func _ready():
	mana = pet.mana_start
	manaBar.max_value = pet.mana_max
	manaBar.value = pet.mana_start
	stateMachine.init(self)
	sprite.texture = pet.texture_card

func _unhandled_input(event: InputEvent) -> void:
	stateMachine.processInput(event)
	
func _physics_process(delta: float) -> void:
	stateMachine.processPhysics(delta)
	
func _process(delta: float) -> void:
	stateMachine.processFrame(delta)
