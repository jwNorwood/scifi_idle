extends Control
class_name SkillDisplayPanel

@onready var skill_list = %SkillList
@onready var add_skill_button = %AddSkillButton

# Test skills for demonstration
var test_skills: Array[Skill] = []

func _ready():
	_load_test_skills()
	_setup_ui()
	refresh_skill_display()
	
	# Connect to skill system events
	if EventBus.player_skills_changed.is_connected(_on_skills_changed):
		EventBus.player_skills_changed.disconnect(_on_skills_changed)
	EventBus.player_skills_changed.connect(_on_skills_changed)

func _load_test_skills():
	"""Load test skills for demonstration"""
	var skill_paths = [
		"res://Resources/Skill/VitalityBoost.tres",
		"res://Resources/Skill/PowerStrike.tres", 
		"res://Resources/Skill/GoldenTouch.tres",
		"res://Resources/Skill/BargainHunter.tres",
		"res://Resources/Skill/TeamExpansion.tres"
	]
	
	for path in skill_paths:
		if ResourceLoader.exists(path):
			var skill = load(path) as Skill
			if skill:
				test_skills.append(skill)

func _setup_ui():
	"""Setup UI elements"""
	if add_skill_button:
		add_skill_button.text = "Add Test Skill"
		add_skill_button.pressed.connect(_on_add_skill_pressed)

func refresh_skill_display():
	"""Refresh the skill list display"""
	if not skill_list:
		return
	
	# Clear existing children
	for child in skill_list.get_children():
		child.queue_free()
	
	# Add player skills
	if GlobalPlayer and GlobalPlayer.skill_manager:
		for skill in GlobalPlayer.skill_manager.player_skills:
			_add_skill_to_list(skill, true)
	
	# Add a separator
	var separator = HSeparator.new()
	skill_list.add_child(separator)
	
	# Add available test skills
	var label = Label.new()
	label.text = "Available Skills:"
	label.add_theme_color_override("font_color", Color.GRAY)
	skill_list.add_child(label)
	
	for skill in test_skills:
		if GlobalPlayer and GlobalPlayer.skill_manager and not GlobalPlayer.skill_manager.has_skill(skill):
			_add_skill_to_list(skill, false)

func _add_skill_to_list(skill: Skill, is_owned: bool):
	"""Add a skill to the display list"""
	var skill_container = HBoxContainer.new()
	
	# Skill name with rarity color
	var name_label = Label.new()
	name_label.text = skill.name + " (Lv." + str(skill.current_level) + ")"
	name_label.add_theme_color_override("font_color", skill.get_rarity_color())
	name_label.custom_minimum_size.x = 150
	skill_container.add_child(name_label)
	
	# Effect description
	var effect_label = Label.new()
	effect_label.text = skill.get_effect_description()
	effect_label.custom_minimum_size.x = 200
	skill_container.add_child(effect_label)
	
	# Current effect value
	var value_label = Label.new()
	value_label.text = skill.get_display_text()
	value_label.add_theme_color_override("font_color", Color.GREEN)
	value_label.custom_minimum_size.x = 80
	skill_container.add_child(value_label)
	
	if is_owned:
		# Upgrade button
		if skill.can_upgrade():
			var upgrade_button = Button.new()
			upgrade_button.text = "Upgrade (" + str(skill.get_upgrade_cost()) + " gold)"
			upgrade_button.pressed.connect(func(): _upgrade_skill(skill))
			skill_container.add_child(upgrade_button)
		else:
			var max_label = Label.new()
			max_label.text = "MAX LEVEL"
			max_label.add_theme_color_override("font_color", Color.GOLD)
			skill_container.add_child(max_label)
	else:
		# Purchase button
		var purchase_button = Button.new()
		purchase_button.text = "Learn (" + str(skill.cost) + " gold)"
		purchase_button.pressed.connect(func(): _purchase_skill(skill))
		# Check if player can afford
		if GlobalPlayer.playerGold < skill.cost:
			purchase_button.disabled = true
		skill_container.add_child(purchase_button)
	
	skill_list.add_child(skill_container)

func _purchase_skill(skill: Skill):
	"""Purchase a new skill"""
	if GlobalPlayer and GlobalPlayer.skill_manager and GlobalPlayer.playerGold >= skill.cost:
		GlobalPlayer.playerGold -= skill.cost
		EventBus.player_gold_change.emit(-skill.cost)
		
		# Create a copy of the skill for the player
		var player_skill = skill.duplicate()
		GlobalPlayer.skill_manager.add_skill(player_skill)
		
		print("Purchased skill: ", skill.name)
		refresh_skill_display()

func _upgrade_skill(skill: Skill):
	"""Upgrade an existing skill"""
	if GlobalPlayer and GlobalPlayer.skill_manager:
		if GlobalPlayer.skill_manager.upgrade_skill(skill):
			print("Upgraded skill: ", skill.name)
			refresh_skill_display()

func _on_add_skill_pressed():
	"""Add a random test skill for demonstration"""
	if test_skills.is_empty() or not GlobalPlayer or not GlobalPlayer.skill_manager:
		return
	
	# Find skills player doesn't have
	var available_skills = []
	for skill in test_skills:
		if not GlobalPlayer.skill_manager.has_skill(skill):
			available_skills.append(skill)
	
	if available_skills.is_empty():
		print("Player already has all test skills!")
		return
	
	# Add a random available skill
	var random_skill = available_skills[randi() % available_skills.size()]
	var player_skill = random_skill.duplicate()
	GlobalPlayer.skill_manager.add_skill(player_skill)
	
	print("Added test skill: ", random_skill.name)

func _on_skills_changed(_skills: Array):
	"""Handle skill changes"""
	refresh_skill_display()
