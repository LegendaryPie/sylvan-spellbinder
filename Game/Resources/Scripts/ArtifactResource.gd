# ArtifactResource.gd - Base Artifact Resource Type
class_name ArtifactResource
extends Resource

enum Rarity {
	NORMAL,
	ELITE,
	TREASURE,
	BOSS
}

# Basic properties
@export var id: String = ""
@export var name: String = "Artifact Name"
@export var description: String = "Artifact description"
@export var rarity: Rarity = Rarity.NORMAL
@export var texture_path: String = "res://Assets/icon.svg"

# Properties for buff/modification effects
@export var damage_bonus: float = 0.0  # Flat damage bonus
@export var damage_multiplier: float = 1.0  # Percentage damage increase
@export var health_bonus: int = 0  # Max health increase
@export var energy_bonus: int = 0  # Max energy increase
@export var heal_multiplier: float = 1.0  # Healing received multiplier
@export var shield_multiplier: float = 1.0  # Shield strength multiplier

# Card modification properties
@export var card_draw_bonus: int = 0  # Additional cards drawn per turn
@export var energy_cost_reduction: int = 0  # Reduce cost of cards by this amount

# Special properties
@export var triggers_on_room_entry: bool = false  # Trigger effect when entering a room
@export var triggers_on_card_play: bool = false  # Trigger effect when playing a card
@export var triggers_on_hit: bool = false  # Trigger effect when taking damage
@export var triggers_on_kill: bool = false  # Trigger effect when killing an enemy

# Visual feedback properties
@export var trigger_effect_color: Color = Color.WHITE
@export var trigger_effect_particles: bool = true
@export var trigger_sound_effect: String = ""

func _init(p_id: String = "", p_name: String = "Artifact Name"):
	id = p_id
	name = p_name

# Create a new instance of this artifact
func create_instance() -> ArtifactResource:
	return self.duplicate()

# Virtual method for special effects when player enters a room
func on_room_entry(_player) -> void:
	pass

# Virtual method for when a card is played
func on_card_played(_player, _card) -> void:
	pass

# Virtual method for when player takes damage
func on_hit(_player, _damage_info) -> void:
	pass

# Virtual method for when player kills an enemy
func on_kill(_player, _enemy) -> void:
	pass

# Return modified damage value based on artifact effects
func modify_damage(base_damage: float) -> float:
	return (base_damage + damage_bonus) * damage_multiplier

# Return modified healing value based on artifact effects
func modify_healing(base_healing: float) -> float:
	return base_healing * heal_multiplier

# Return modified shield value based on artifact effects
func modify_shield(base_shield: float) -> float:
	return base_shield * shield_multiplier

# Return modified card energy cost
func modify_card_cost(base_cost: int) -> int:
	return max(0, base_cost - energy_cost_reduction)
