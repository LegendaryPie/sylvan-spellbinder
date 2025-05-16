extends ArtifactResource

var first_attack: bool = true

func on_room_entry(_player) -> void:
	first_attack = true

func on_card_played(_player, card) -> void:
	if first_attack and card.is_attack:
		first_attack = false
		card.damage_multiplier *= 2.0
