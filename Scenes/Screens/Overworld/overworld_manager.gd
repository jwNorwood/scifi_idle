extends Node

@export var encounter: PackedScene
@export var maxDepth: int = 10
@export var maxWidth: int = 5

var storedWorld
var spawnLocation
var initialMove: bool = true
var currentEncounter: Encounter
var playerMoving: bool = false
var isInEncounter: bool = false

@onready var map = %Map
@onready var modal = %ModalEncounterInfo
@onready var player: OverworldPlayer = %Player
@onready var activeEncounter = %ActiveEncounter
@onready var overworldContent = %OverworldContent


var levelTree = {
	"type": "start",
	"children": [],
	"depth": 0,
	"added": false,
	"id": 0,
	}

enum encounters { WILD, TRAINER, MYSTERY, SHOP } 

# Called when the node enters the scene tree for the first time.

func _ready():
	player.travel_finished.connect(playerFinishedTravel)
	
	var world = buildTree(levelTree, maxDepth)
	storedWorld = world
	displayWorld(world)
	drawPaths()

func playerFinishedTravel():
	playerMoving = false
	overworldContent.hide()
	isInEncounter = true
	# transition animation	
	currentEncounter.enterEncounter(activeEncounter)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (isInEncounter && activeEncounter.get_child_count() == 0):
		overworldContent.show()
	if (!initialMove):
		return
	if (!spawnLocation):
		spawnLocation = map.get_child(0)
		currentEncounter = map.get_child(0)
	if (spawnLocation):
		player.global_position = spawnLocation.getPosition()
	


func selectedEncounter(encounter: Encounter):
	if(playerMoving):
		return
	print("selected: ", encounter.id)
	modal.setTitle(str(encounter.id))
	modal.setDescription(str(encounter.id))
	initialMove = false
	playerMoving = true
	player.travelToEncounter(encounter.id, encounter.global_position)
	currentEncounter = encounter

func hoveredEncounter(hoveredId):
	print("hovered: ", hoveredId)

func playerUseItem(item):
	print(item)

# Level Buliding
func randomEncounter():
	return encounters.values().pick_random()

var id = 0 

func createNewNode(currentDepth: int):
	id = id + 1
	var newNode = {
		"type": randomEncounter(),
		"children": [],
		"depth": currentDepth,
		"added": false,
		"id": id,
	}
	return newNode

func buildTree(tree, depth):
	if (depth == 0):
		return tree
	else:
		var left = createNewNode(tree.depth + 1)
		tree.children.append(left)
		
		# 50% chance of having a right child
		# alter the chance based on the previous number of branches
		if (tree.id == 0 || tree.id % 2 == 0 && randi() % 2 == 0 ):
			var right = createNewNode(tree.depth + 1)
			tree.children.append(right)
			buildTree(right, depth - 1)
		
		buildTree(left, depth - 1)
		return tree

func findNodesAtDepth(tree, depth):
	var nodes = []
	if (tree.depth == depth):
		nodes.append(tree)
	else:
		for child in tree.children:
			nodes.append(findNodesAtDepth(child, depth))
	return nodes

func recursiveSearch(tree, target):
	if (tree.type == target):
		return tree
	else:
		for child in tree.children:
			return recursiveSearch(child, target)

func recursiveAdd(tree):
	# Create the node
	if (tree.added):
		return
	else:
		tree.added = true
		var newNode = encounter.instantiate()
		# Set the type
		newNode.nodeType = tree.type
		newNode.childNodes = tree.children
		newNode.id = tree.id
		newNode.depth = tree.depth
		newNode.encounter_selected.connect(selectedEncounter)
		newNode.encounter_hovered.connect(hoveredEncounter)
		
		# Add the node to the scene
		map.add_child(newNode)
		# Add the children
		for child in tree.children:
			recursiveAdd(child)
		return

func getEncounters():
	var e = get_tree().get_nodes_in_group("encounter")
	return e

func displayWorld(worldInfo):
	recursiveAdd(worldInfo)

# space encounters and draw paths between encounters
func drawPaths():
	pass

func organizeWorld():
	pass

# make last node a boss
# link chiless nodes to a node at a deeper level


func populateWorld():
	pass
