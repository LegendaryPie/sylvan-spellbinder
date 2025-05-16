extends ArtifactResource

func on_room_entry(player) -> void:
	var hand_size = player.find_child("CardDeckManager").hand.size()
	player.heal(2 * hand_size)
