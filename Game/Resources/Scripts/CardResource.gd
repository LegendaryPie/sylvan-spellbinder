# CardResource.gd - Base Card Resource Type
class_name CardResource
extends Resource

enum CardType {
	ATTACK,
	DEFENSE,
	UTILITY
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY
}

@export var id: String = ""
@export var name: String = "Card Name"
@export var type: CardType = CardType.ATTACK
@export var energy_cost: int = 10
@export var description: String = "Card description goes here."
@export var texture_path: String = "res://assets/cards/default_card.png"
@export var rarity: Rarity = Rarity.COMMON
@export var effects: Array[CardEffectResource] = []
@export var exhaust: bool = false  # If true, card is removed from deck until room change

# Optional card properties
@export var cooldown: float = 0.0 # If the card needs a cooldown between uses

# Audio properties
@export var cast_sound_path: String = "res://assets/sounds/cards/default_cast.wav"

# Visual effects
@export var cast_particles_path: String = ""

func _init(p_id: String = "", p_name: String = "Card Name"):
	id = p_id
	name = p_name

# Execute all effects of this card
func execute(caster, target_position: Vector2, direction: Vector2):
	for effect in effects:
		effect.execute(caster, target_position, direction)
	
	return true

# Clone this card (for creating deck instances)
func create_instance() -> CardResource:
	var instance = self.duplicate()
	return instance

func get_formatted_description() -> String:
	var formatted = description
	
	# Replace placeholders with actual values from effects
	for effect in effects:
		var effect_values = effect.get_description_values()
		for key in effect_values:
			formatted = formatted.replace("{" + key + "}", str(effect_values[key]))
	
	return formatted
