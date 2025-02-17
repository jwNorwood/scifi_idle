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

func getColor():
	# return color based on encounter type and nodeType
	match  nodeType:
		encounters.WILD:
			return Color.OLIVE_DRAB
		encounters.TRAINER:
			return Color.DARK_CYAN
		encounters.MYSTERY:
			return Color.MEDIUM_PURPLE
		encounters.SHOP:
			return Color.INDIAN_RED
		_:
			return Color(1, 1, 1)

func _ready():
	depthLabel.text = str(depth)
	color.set_color(getColor())
	# shader for player location
	# differnent node?		

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

func _process(_delta):
	return
	queue_redraw()

func getNodeById(i):
	var encounters = getEncounters()
	for encounter in encounters:
		if (encounter.id == i):
			return encounter
	return null

func getRelativePosition(childPosition: Vector2):
	var currentNodePosition = get_global_position()
	var relativePosition = childPosition - currentNodePosition
	return relativePosition

func getPosition():
	return get_global_position()

func _on_sleeping_state_changed():
	drawArrows()

func enterEncounter(parent: Node):
	# based on details, enter scene
	print("now entering the encounter")
	
	# add scene into parent	
	var scene = load('res://Scenes/Screens/Combat/Combat.tscn').instantiate()
	parent.add_child(scene)

func _on_button_pressed() -> void:
	encounter_selected.emit(self)

func _on_button_mouse_entered() -> void:
	encounter_hovered.emit(id)
	print("position: ", getPosition())
