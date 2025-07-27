class_name SkillEnums

# Skill type categorization
enum SkillType {
	COMBAT,      # Combat-related buffs (HP, damage, speed)
	ECONOMIC,    # Gold and reward bonuses
	SHOP,        # Shop discounts and special offers
	UTILITY      # Miscellaneous bonuses
}

# Skill effects - these define what the skill actually does
enum EffectType {
	# Combat effects
	HEALTH_PERCENT,     # +X% to max health
	HEALTH_FLAT,        # +X to max health
	ATTACK_PERCENT,     # +X% to attack damage
	ATTACK_FLAT,        # +X to attack damage
	SPEED_PERCENT,      # +X% to speed
	SPEED_FLAT,         # +X to speed
	MANA_PERCENT,       # +X% to max mana
	MANA_FLAT,          # +X to max mana
	
	# Economic effects
	GOLD_REWARD_PERCENT,    # +X% gold from combat rewards
	GOLD_REWARD_FLAT,       # +X gold from combat rewards
	EXP_REWARD_PERCENT,     # +X% experience from combat
	
	# Shop effects
	SHOP_DISCOUNT_PERCENT,  # X% discount on all shop items
	SHOP_DISCOUNT_FLAT,     # X gold discount on all shop items
	
	# Utility effects
	CAPTURE_RATE_PERCENT,   # +X% pet capture rate
	TEAM_SIZE_BONUS         # +X to maximum team size
}

# Skill rarity levels
enum Rarity {
	COMMON,
	UNCOMMON, 
	RARE,
	EPIC,
	LEGENDARY
}
