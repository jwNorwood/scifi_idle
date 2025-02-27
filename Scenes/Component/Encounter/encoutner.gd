extends RigidBody2D
class_name Encounter

var childNodes: Array = []
var id: int
var depth: int = 0

@onready var depthLabel = %Depth
@onready var color = %ColorRect

# change to enum
var nodeType
enum encounters { WILD, TRAINER, MYSTERY, SHOP } 

signal encounter_selected(encounter: Encounter)
signal encounter_hovered(id: int)

func getEncounterInfo():
	match  nodeType:
		encounters.WILD:
			return {
				"color": Color.OLIVE_DRAB,
				"scene": 'res://Scenes/Screens/Combat/Combat.tscn'
			}
		encounters.TRAINER:
			return {
				"color": Color.DARK_CYAN,
				"scene": 'res://Scenes/Screens/Combat/Combat.tscn'
			}
		encounters.MYSTERY:
			return {
				"color": Color.MEDIUM_PURPLE,
				"scene": 'res://Scenes/Screens/Combat/Combat.tscn'
			}
		encounters.SHOP:
			return {
				"color": Color.INDIAN_RED,
				"scene": 'res://Scenes/Screens/Combat/Combat.tscn'
			}
		_:
			return {
				"color": Color.WHITE,
				"scene": 'res://Scenes/Screens/Combat/Combat.tscn'
			}

func _ready():
	depthLabel.text = str(depth)
	color.set_color(getEncounterInfo().color)

func getEncounters():
	var encounters = get_tree().get_nodes_in_group("encounter")
	return encounters

# move towards child nodes
func moveToChildNodes():
	return

func drawArrows():
	queue_redraw()

func _draw():
	var path = Color.TAN
	if (childNodes.size() == 0):
		return
	for child in childNodes:
		if (!child):
			return
		var center = getPosition()
		var c = getNodeById(child.id)
		if (!c):
			return
		var childCenter = c.getPosition()
		draw_line(Vector2(0 , 0), Vector2(to_local(childCenter).x, to_local(childCenter).y), path, 4)

func getNodeById(i):
	var encounters = getEncounters()
	for encounter in encounters:
		if (encounter.id == i):
			return encounter
	return null
	
func hasChildNode(id):
	for child in childNodes:
		if child.id == id:
			return true
	return false

func getRelativePosition(childPosition: Vector2):
	var currentNodePosition = get_global_position()
	var relativePosition = childPosition - currentNodePosition
	return relativePosition

func getPosition():
	return get_global_position()

func _on_sleeping_state_changed():
	drawArrows()

func enterEncounter(parent: Node):
	var scene = load(getEncounterInfo().scene).instantiate()
	parent.add_child(scene)

func _on_button_pressed() -> void:
	encounter_selected.emit(self)

func _on_button_mouse_entered() -> void:
	encounter_hovered.emit(id)
