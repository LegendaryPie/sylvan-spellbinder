extends ArtifactResource

func on_room_entry(player) -> void:
	var hand = player.find_child("CardDeckManager").hand
	if hand.size() > 0:
		var random_card = hand[randi() % hand.size()]
		random_card.energy_cost = 0
