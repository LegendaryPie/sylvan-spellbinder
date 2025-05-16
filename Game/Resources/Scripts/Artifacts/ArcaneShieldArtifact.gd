extends ArtifactResource

var first_hit: bool = true

func on_room_entry(_player) -> void:
	first_hit = true

func on_hit(_player, damage_info) -> void:
	if first_hit:
		first_hit = false
		damage_info.damage = 0
