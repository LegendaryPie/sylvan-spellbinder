extends ArtifactResource

func on_kill(player, _enemy) -> void:
	player.heal(5)
	player.energy = min(player.energy + 1, player.max_energy)
