# Skill System Documentation

## Overview

The skill system provides persistent upgrades for the player that enhance combat performance, economic rewards, and utility features. Skills can be acquired, upgraded, and provide various bonuses throughout the game.

## Core Components

### 1. Skill Resource (`Resources/Skill/Skill.gd`)

The base class for all skills with the following key features:

- **Effect Types**: Combat (HP, damage, speed), Economic (gold, XP), Shop (discounts), Utility (team size, capture rate)
- **Rarity System**: Common, Uncommon, Rare, Epic, Legendary with color coding
- **Upgrade System**: Skills can be upgraded multiple times with increasing costs
- **Display Methods**: Automatic formatting for UI display

### 2. SkillManager (`Classes/SkillManager.gd`)

Manages the player's skill collection and applies modifiers:

- **Skill Collection**: Add, remove, and upgrade skills
- **Modifier Calculation**: Caches and applies bonuses efficiently
- **Integration**: Automatically applies modifiers to pets and rewards

### 3. Integration Points

The skill system is integrated into:

- **GlobalPlayer**: Contains the SkillManager instance
- **Combat Manager**: Applies modifiers to rewards and pet stats
- **EventBus**: Skill-related events for UI updates

## Skill Types and Effects

### Combat Skills

- **Health Percent/Flat**: Increases pet health
- **Attack Percent/Flat**: Increases pet damage
- **Speed Percent/Flat**: Increases pet speed
- **Mana Percent/Flat**: Increases pet mana

### Economic Skills

- **Gold Reward Percent/Flat**: Increases gold from combat
- **Experience Reward Percent**: Increases XP from combat

### Shop Skills

- **Shop Discount Percent/Flat**: Reduces shop prices

### Utility Skills

- **Capture Rate Percent**: Increases pet capture chance
- **Team Size Bonus**: Adds extra team slots

## Example Skills Created

1. **Vitality Boost** (Common)

   - +10% health for all pets
   - Upgradeable to +35% at max level

2. **Power Strike** (Uncommon)

   - +15% attack damage for all pets
   - Upgradeable to +40% at max level

3. **Golden Touch** (Rare)

   - +25% gold from combat
   - Upgradeable to +55% at max level

4. **Bargain Hunter** (Uncommon)

   - 15% shop discount
   - Upgradeable to 35% discount at max level

5. **Team Expansion** (Epic)
   - +1 team slot
   - Upgradeable to +4 team slots at max level

## Usage Examples

### Adding a Skill to Player

```gdscript
var skill = load("res://Resources/Skill/VitalityBoost.tres") as Skill
GlobalPlayer.skill_manager.add_skill(skill)
```

### Upgrading a Skill

```gdscript
if GlobalPlayer.skill_manager.upgrade_skill(skill):
    print("Skill upgraded successfully!")
```

### Getting Modifiers

```gdscript
# Get health multiplier (1.1 = +10% health)
var health_mult = GlobalPlayer.skill_manager.get_health_multiplier()

# Get gold reward with bonuses
var final_gold = GlobalPlayer.skill_manager.calculate_final_gold_reward(base_gold)
```

### Creating New Skills

1. Create a new `.tres` file in `Resources/Skill/`
2. Set the script to `Skill.gd`
3. Configure the skill properties:
   - `name`: Display name
   - `description`: Brief description
   - `skill_type`: Category (Combat, Economic, Shop, Utility)
   - `effect_type`: Specific effect (Health Percent, Gold Reward, etc.)
   - `effect_value`: Base bonus amount
   - `rarity`: Skill rarity level
   - `cost`: Purchase/unlock cost
   - `max_level`: Maximum upgrade level

## Integration with Combat

The combat manager automatically:

- Applies skill modifiers to player pets before combat
- Calculates final rewards with skill bonuses
- Uses modified stats for combat calculations

## UI Integration

The `SkillDisplayPanel` provides:

- List of owned and available skills
- Upgrade buttons with costs
- Purchase options for new skills
- Real-time updates when skills change

## Future Expansion Ideas

- **Skill Trees**: Interconnected skill progression
- **Skill Sets**: Bonus effects for collecting related skills
- **Skill Gems**: Socketed skills that can be swapped
- **Mastery Levels**: Additional progression beyond max level
- **Skill Synergies**: Bonus effects when certain skills are combined

## Testing

To test the skill system:

1. Open the skill display panel scene
2. Use "Add Test Skill" to give yourself skills
3. Test upgrading skills (requires gold)
4. Enter combat to see modifier effects
5. Check reward calculations after victory
