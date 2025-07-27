extends Node
class_name SkillManager

# Preload the global enums
const SkillEnums = preload("res://Classes/SkillEnums.gd")

# Constants for calculations
const PERCENTAGE_DIVISOR: float = 100.0
const BASE_MULTIPLIER: float = 1.0
const DEFAULT_MODIFIER_VALUE: float = 0.0
const MINIMUM_SHOP_PRICE: int = 1

# Player's acquired skills
var player_skills: Array[Skill] = []

# Cached modifiers for performance
var _cached_modifiers: Dictionary = {}
var _cache_dirty: bool = true

# Initialize the skill manager
func _ready():
	# Connect to relevant events
	EventBus.player_level_change.connect(_on_player_level_changed)

func add_skill(skill: Skill) -> bool:
	"""Add a skill to the player's collection"""
	if skill and not has_skill(skill):
		player_skills.append(skill)
		_cache_dirty = true
		EventBus.player_skills_changed.emit(player_skills)
		print("Added skill: ", skill.name)
		return true
	return false

func remove_skill(skill: Skill) -> bool:
	"""Remove a skill from the player's collection"""
	var index = player_skills.find(skill)
	if index >= 0:
		player_skills.remove_at(index)
		_cache_dirty = true
		EventBus.player_skills_changed.emit(player_skills)
		print("Removed skill: ", skill.name)
		return true
	return false

func has_skill(skill: Skill) -> bool:
	"""Check if player has a specific skill"""
	for player_skill in player_skills:
		if player_skill.name == skill.name:
			return true
	return false

func upgrade_skill(skill: Skill) -> bool:
	"""Upgrade a skill if possible and player has enough gold"""
	if not has_skill(skill) or not skill.can_upgrade():
		return false
	
	var upgrade_cost = skill.get_upgrade_cost()
	if GlobalPlayer.playerGold >= upgrade_cost:
		GlobalPlayer.playerGold -= upgrade_cost
		skill.upgrade()
		_cache_dirty = true
		EventBus.player_gold_change.emit(-upgrade_cost)
		EventBus.player_skills_changed.emit(player_skills)
		print("Upgraded skill: ", skill.name, " to level ", skill.current_level)
		return true
	
	return false

func get_skills_by_type(skill_type: SkillEnums.SkillType) -> Array[Skill]:
	"""Get all skills of a specific type"""
	var filtered_skills: Array[Skill] = []
	for skill in player_skills:
		if skill.skill_type == skill_type:
			filtered_skills.append(skill)
	return filtered_skills

func _update_modifier_cache():
	"""Update cached modifiers for performance"""
	if not _cache_dirty:
		return
	
	_cached_modifiers.clear()
	
	# Initialize all modifier types to 0
	for effect_type in SkillEnums.EffectType.values():
		_cached_modifiers[effect_type] = DEFAULT_MODIFIER_VALUE
	
	# Sum up all skill effects
	for skill in player_skills:
		var current_value = _cached_modifiers.get(skill.effect_type, 0.0)
		_cached_modifiers[skill.effect_type] = current_value + skill.get_total_effect_value()
	
	_cache_dirty = false
	print("Updated skill modifier cache: ", _cached_modifiers)

func get_modifier(effect_type: SkillEnums.EffectType) -> float:
	"""Get the total modifier value for a specific effect type"""
	_update_modifier_cache()
	return _cached_modifiers.get(effect_type, 0.0)

# Combat stat modifiers
func get_health_multiplier() -> float:
	"""Get total health multiplier (1.0 = no bonus, 1.1 = +10%)"""
	return BASE_MULTIPLIER + (get_modifier(SkillEnums.EffectType.HEALTH_PERCENT) / PERCENTAGE_DIVISOR)

func get_health_bonus() -> int:
	"""Get flat health bonus"""
	return int(get_modifier(SkillEnums.EffectType.HEALTH_FLAT))

func get_attack_multiplier() -> float:
	"""Get total attack multiplier (1.0 = no bonus, 1.1 = +10%)"""
	return BASE_MULTIPLIER + (get_modifier(SkillEnums.EffectType.ATTACK_PERCENT) / PERCENTAGE_DIVISOR)

func get_attack_bonus() -> float:
	"""Get flat attack bonus"""
	return get_modifier(SkillEnums.EffectType.ATTACK_FLAT)

func get_speed_multiplier() -> float:
	"""Get total speed multiplier (1.0 = no bonus, 1.1 = +10%)"""
	return BASE_MULTIPLIER + (get_modifier(SkillEnums.EffectType.SPEED_PERCENT) / PERCENTAGE_DIVISOR)

func get_speed_bonus() -> float:
	"""Get flat speed bonus"""
	return get_modifier(SkillEnums.EffectType.SPEED_FLAT)

func get_mana_multiplier() -> float:
	"""Get total mana multiplier (1.0 = no bonus, 1.1 = +10%)"""
	return BASE_MULTIPLIER + (get_modifier(SkillEnums.EffectType.MANA_PERCENT) / PERCENTAGE_DIVISOR)

func get_mana_bonus() -> int:
	"""Get flat mana bonus"""
	return int(get_modifier(SkillEnums.EffectType.MANA_FLAT))

# Economic modifiers
func get_gold_reward_multiplier() -> float:
	"""Get gold reward multiplier"""
	return BASE_MULTIPLIER + (get_modifier(SkillEnums.EffectType.GOLD_REWARD_PERCENT) / PERCENTAGE_DIVISOR)

func get_gold_reward_bonus() -> int:
	"""Get flat gold reward bonus"""
	return int(get_modifier(SkillEnums.EffectType.GOLD_REWARD_FLAT))

func get_experience_multiplier() -> float:
	"""Get experience multiplier"""
	return BASE_MULTIPLIER + (get_modifier(SkillEnums.EffectType.EXP_REWARD_PERCENT) / PERCENTAGE_DIVISOR)

# Shop modifiers
func get_shop_discount_multiplier() -> float:
	"""Get shop discount multiplier (0.9 = 10% discount)"""
	return BASE_MULTIPLIER - (get_modifier(SkillEnums.EffectType.SHOP_DISCOUNT_PERCENT) / PERCENTAGE_DIVISOR)

func get_shop_discount_flat() -> int:
	"""Get flat shop discount"""
	return int(get_modifier(SkillEnums.EffectType.SHOP_DISCOUNT_FLAT))

# Utility modifiers
func get_capture_rate_bonus() -> float:
	"""Get capture rate bonus percentage"""
	return get_modifier(SkillEnums.EffectType.CAPTURE_RATE_PERCENT)

func get_team_size_bonus() -> int:
	"""Get bonus team slots"""
	return int(get_modifier(SkillEnums.EffectType.TEAM_SIZE_BONUS))

func get_max_team_size() -> int:
	"""Get maximum team size including bonuses"""
	return Skill.BASE_TEAM_SIZE + get_team_size_bonus()  # Base team size from Skill constant

# Utility functions for applying modifiers
func apply_pet_modifiers(pet: Pet) -> Pet:
	"""Apply skill modifiers to a pet's stats"""
	if not pet:
		return pet
	
	# Apply health modifiers
	pet.health = int((pet.health + get_health_bonus()) * get_health_multiplier())
	
	# Apply attack modifiers
	pet.attack = (pet.attack + get_attack_bonus()) * get_attack_multiplier()
	
	# Apply speed modifiers
	pet.speed = (pet.speed + get_speed_bonus()) * get_speed_multiplier()
	
	# Apply mana modifiers
	pet.mana_max = int((pet.mana_max + get_mana_bonus()) * get_mana_multiplier())
	pet.mana_start = pet.mana_max
	
	return pet

func calculate_final_gold_reward(base_gold: int) -> int:
	"""Calculate final gold reward with all modifiers"""
	var final_gold = (base_gold + get_gold_reward_bonus()) * get_gold_reward_multiplier()
	return int(final_gold)

func calculate_final_experience(base_exp: int) -> int:
	"""Calculate final experience with all modifiers"""
	var final_exp = base_exp * get_experience_multiplier()
	return int(final_exp)

func calculate_shop_price(base_price: int) -> int:
	"""Calculate final shop price with all discounts"""
	var discounted_price = (base_price - get_shop_discount_flat()) * get_shop_discount_multiplier()
	return max(MINIMUM_SHOP_PRICE, int(discounted_price))  # Minimum price of 1

# Event handlers
func _on_player_level_changed(new_level: int):
	"""Handle player level changes to unlock new skills"""
	print("Player reached level ", new_level, " - checking for skill unlocks")
	# This could trigger skill unlock notifications

# Save/Load functionality
func get_save_data() -> Dictionary:
	"""Get skill data for saving"""
	var save_data = {
		"skills": []
	}
	
	for skill in player_skills:
		save_data.skills.append({
			"name": skill.name,
			"current_level": skill.current_level
		})
	
	return save_data

func load_save_data(data: Dictionary):
	"""Load skill data from save"""
	player_skills.clear()
	
	if data.has("skills"):
		for skill_data in data.skills:
			# You would need to implement a skill database/registry here
			# For now, this is a placeholder for the loading system
			print("Loading skill: ", skill_data.name, " at level ", skill_data.current_level)
	
	_cache_dirty = true
