extends ArtifactResource

func on_card_played(player, card) -> void:
	if player.health <= player.max_health / 2 and card.is_attack:
		card.damage_multiplier *= 1.5
