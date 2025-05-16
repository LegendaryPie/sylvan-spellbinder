extends ArtifactResource

func on_room_entry(player) -> void:
	player.heal(5)
