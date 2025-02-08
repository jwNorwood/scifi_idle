extends SpecialAttack

func trigger_attack(player: Player) -> void:
	player.doDamage(5)
	print("Fireball!")
	return
