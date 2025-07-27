extends Resource
class_name Skill

# Preload the global enums
const SkillEnums = preload("res://Classes/SkillEnums.gd")

# Constants for default values
const DEFAULT_EFFECT_VALUE: float = 10.0
const DEFAULT_UNLOCK_LEVEL: int = 1
const DEFAULT_BASE_COST: int = 100
const DEFAULT_MAX_LEVEL: int = 5
const DEFAULT_CURRENT_LEVEL: int = 1
const DEFAULT_VALUE_PER_LEVEL: float = 2.0
const BASE_TEAM_SIZE: int = 5
const MINIMUM_SHOP_PRICE: int = 1

# Basic skill information
@export var name: String
@export var description: String
@export var icon: Texture

# Skill type for categorization
@export var skill_type: SkillEnums.SkillType = SkillEnums.SkillType.COMBAT

# The effect this skill provides
@export var effect_type: SkillEnums.EffectType = SkillEnums.EffectType.HEALTH_PERCENT
@export var effect_value: float = DEFAULT_EFFECT_VALUE  # The numerical value (e.g., 10 for 10%)

# Skill rarity and unlock requirements
@export var rarity: SkillEnums.Rarity = SkillEnums.Rarity.COMMON
@export var unlock_level: int = DEFAULT_UNLOCK_LEVEL  # Player level required to unlock
@export var cost: int = DEFAULT_BASE_COST        # Cost to purchase/upgrade

# Upgrade system
@export var max_level: int = DEFAULT_MAX_LEVEL
@export var current_level: int = DEFAULT_CURRENT_LEVEL
@export var value_per_level: float = DEFAULT_VALUE_PER_LEVEL  # How much effect_value increases per level

# Methods for skill functionality
func get_total_effect_value() -> float:
	"""Get the total effect value including upgrades"""
	return effect_value + (value_per_level * (current_level - DEFAULT_CURRENT_LEVEL))

func get_display_text() -> String:
	"""Get formatted text for UI display"""
	var value = get_total_effect_value()
	var suffix = ""
	
	# Determine if this is a percentage or flat bonus
	match effect_type:
		SkillEnums.EffectType.HEALTH_PERCENT, SkillEnums.EffectType.ATTACK_PERCENT, SkillEnums.EffectType.SPEED_PERCENT, \
		SkillEnums.EffectType.MANA_PERCENT, SkillEnums.EffectType.GOLD_REWARD_PERCENT, SkillEnums.EffectType.EXP_REWARD_PERCENT, \
		SkillEnums.EffectType.SHOP_DISCOUNT_PERCENT, SkillEnums.EffectType.CAPTURE_RATE_PERCENT:
			suffix = "%"
		SkillEnums.EffectType.HEALTH_FLAT, SkillEnums.EffectType.ATTACK_FLAT, SkillEnums.EffectType.SPEED_FLAT, \
		SkillEnums.EffectType.MANA_FLAT, SkillEnums.EffectType.GOLD_REWARD_FLAT, SkillEnums.EffectType.SHOP_DISCOUNT_FLAT:
			suffix = ""
		SkillEnums.EffectType.TEAM_SIZE_BONUS:
			suffix = " slots"
	
	return "+" + str(value) + suffix

func get_rarity_color() -> Color:
	"""Get color associated with skill rarity"""
	match rarity:
		SkillEnums.Rarity.COMMON:
			return Color.WHITE
		SkillEnums.Rarity.UNCOMMON:
			return Color.GREEN
		SkillEnums.Rarity.RARE:
			return Color.BLUE
		SkillEnums.Rarity.EPIC:
			return Color.PURPLE
		SkillEnums.Rarity.LEGENDARY:
			return Color.GOLD
		_:
			return Color.WHITE

func can_upgrade() -> bool:
	"""Check if skill can be upgraded further"""
	return current_level < max_level

func get_upgrade_cost() -> int:
	"""Get cost to upgrade to next level"""
	if not can_upgrade():
		return 0
	return cost + (cost * current_level)  # Cost increases with each level

func upgrade() -> bool:
	"""Upgrade the skill to next level"""
	if can_upgrade():
		current_level += 1
		return true
	return false

func get_category_name() -> String:
	"""Get human-readable category name"""
	match skill_type:
		SkillEnums.SkillType.COMBAT:
			return "Combat"
		SkillEnums.SkillType.ECONOMIC:
			return "Economic"
		SkillEnums.SkillType.SHOP:
			return "Shop"
		SkillEnums.SkillType.UTILITY:
			return "Utility"
		_:
			return "Unknown"

func get_effect_description() -> String:
	"""Get detailed description of what this skill does"""
	var value_text = get_display_text()
	
	match effect_type:
		SkillEnums.EffectType.HEALTH_PERCENT:
			return value_text + " maximum health for all pets"
		SkillEnums.EffectType.HEALTH_FLAT:
			return value_text + " maximum health for all pets"
		SkillEnums.EffectType.ATTACK_PERCENT:
			return value_text + " attack damage for all pets"
		SkillEnums.EffectType.ATTACK_FLAT:
			return value_text + " attack damage for all pets"
		SkillEnums.EffectType.SPEED_PERCENT:
			return value_text + " speed for all pets"
		SkillEnums.EffectType.SPEED_FLAT:
			return value_text + " speed for all pets"
		SkillEnums.EffectType.MANA_PERCENT:
			return value_text + " maximum mana for all pets"
		SkillEnums.EffectType.MANA_FLAT:
			return value_text + " maximum mana for all pets"
		SkillEnums.EffectType.GOLD_REWARD_PERCENT:
			return value_text + " gold from combat victories"
		SkillEnums.EffectType.GOLD_REWARD_FLAT:
			return value_text + " gold from combat victories"
		SkillEnums.EffectType.EXP_REWARD_PERCENT:
			return value_text + " experience from combat"
		SkillEnums.EffectType.SHOP_DISCOUNT_PERCENT:
			return value_text + " discount on all shop purchases"
		SkillEnums.EffectType.SHOP_DISCOUNT_FLAT:
			return value_text + " gold discount on all shop purchases"
		SkillEnums.EffectType.CAPTURE_RATE_PERCENT:
			return value_text + " pet capture rate"
		SkillEnums.EffectType.TEAM_SIZE_BONUS:
			return value_text + " to maximum team size"
		_:
			return "Unknown effect"
