# CardEffectResource.gd - Base Effect Resource Type
class_name CardEffectResource
extends Resource

@export var effect_type: String = "damage" # damage, heal, shield, movement, etc.
@export var duration: float = 0.0 # Duration of effect (if applicable)

# Scene to instantiate for this effect (if applicable)
@export var effect_scene_path: String = ""

# Base execute method - to be overridden by specific effect types
func execute(caster, target_position: Vector2, direction: Vector2):
	push_error("Base CardEffectResource.execute() called - should be overridden")

# Get values to replace in description text
func get_description_values() -> Dictionary:
	return {}
