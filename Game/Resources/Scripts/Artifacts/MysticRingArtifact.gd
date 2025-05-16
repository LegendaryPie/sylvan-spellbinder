extends ArtifactResource

var first_card_played: bool = false

func on_room_entry(_player) -> void:
	first_card_played = false

func on_card_played(_player, card) -> void:
	if !first_card_played:
		first_card_played = true
		card.energy_cost = max(0, card.energy_cost - 1)
