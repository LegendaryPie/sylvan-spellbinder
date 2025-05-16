extends ArtifactResource

func on_hit(player, _damage) -> void:
	player.add_shield(5)
