extends Node
class_name Player

@export var pet_scene: PackedScene
@export var team: Array[Resource]

@export var targetNode: String = "enemy"

@onready var team_scene = %Team
@onready var healthBar = %HealthBar

@export var reverseOrder: bool = false
@onready var content = %Content

@onready var gameManager = %GameManager

var health: int = 0:
	set = setHealth
	
var maxHealth: int = 0

func getTarget():
	var enemy = get_tree().get_first_node_in_group(targetNode) as Node
	if (!enemy):
		return
	return enemy

func _ready():
	var initialHealth = 0
	
	if(reverseOrder):
		for child in content.get_children():
			content.move_child(child, 0)

	for pet in team:
		initialHealth += pet.health
		var newPet = pet_scene.instantiate()
		newPet.parent = self
		newPet.pet = pet
		team_scene.add_child(newPet)

	healthBar.value = initialHealth
	healthBar.max_value = initialHealth
	health = initialHealth

func addPet(p):
	if (!pet_scene):
		pass
	
func takeDamage(amount):
	health = health - amount
	if (health <= 0):
		return true
	
func doDamage(amount):
	if (health <= 0):
		return
	var target = getTarget()
	var targetDead = target.takeDamage(amount)
	
	if (targetDead && targetNode == "enemy"):
		gameManager.onGameEnd(true)
	if (targetDead && targetNode == "player"):
		gameManager.onGameEnd(false)
	return targetDead

func setHealth(amount):
	if (amount <= 0):
		print("dead")
		health = 0
		healthBar.value = 0
		return
	if (amount < health ):
		print("Take Damage")
	else:
		print("heal")
	health = amount
	healthBar.value = amount


func _on_button_pressed():
	pass # Replace with function body.
