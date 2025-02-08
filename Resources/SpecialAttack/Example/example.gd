extends SpecialAttack

func trigger_attack(player: Player) -> void:
	print("this is an example special attack")
	player.doDamage(5)
	return
