extends ArtifactResource

func on_room_entry(player) -> void:
	var hand = player.find_child("CardDeckManager").hand
	if hand.size() > 0:
		var most_expensive = hand[0]
		for card in hand:
			if card.energy_cost > most_expensive.energy_cost:
				most_expensive = card
		most_expensive.energy_cost = 0
