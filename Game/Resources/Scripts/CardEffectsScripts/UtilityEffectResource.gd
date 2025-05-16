# UtilityEffectResource.gd - Utility Effect Resource Type
class_name UtilityEffectResource
extends CardEffectResource

enum UtilityType {
	HEAL,
	MOVEMENT,
	SHIELD,
	BUFF,
	DEBUFF
}

@export var utility_type: UtilityType = UtilityType.HEAL
@export var value: int = 10 # Amount of healing, shield, movement distance, etc.
@export var movement_speed: float = 500 # For movement effects
@export var buff_multiplier: float = 1.5 # For buff effects
@export var debuff_multiplier: float = 0.5 # For debuff effects

func _init():
	effect_type = "utility"

func execute(caster, target_position: Vector2, direction: Vector2):
	# Load and instantiate effect scene if specified
	if not effect_scene_path.is_empty() and ResourceLoader.exists(effect_scene_path):
		var effect_scene = load(effect_scene_path)
		var effect_instance = effect_scene.instantiate()
		
		# Configure the effect based on properties
		match utility_type:
			UtilityType.HEAL:
				effect_instance.set_heal_amount(value)
				caster.heal(value)
			
			UtilityType.MOVEMENT:
				effect_instance.set_movement_properties(direction, value, movement_speed)
				
				# If no effect scene is provided, we can directly move the caster
				if effect_scene_path.is_empty():
					_apply_movement_effect(caster, direction, value, movement_speed)
			
			UtilityType.SHIELD:
				if effect_instance.has_method("set_shield_properties"):
					effect_instance.set_shield_properties(value, duration)
				# Apply shield directly to caster
				if caster.has_method("add_shield"):
					caster.add_shield(value, duration)
			UtilityType.BUFF:
				effect_instance.set_buff_properties(value, duration, buff_multiplier)
				
			UtilityType.DEBUFF:
				effect_instance.set_debuff_properties(value, duration, debuff_multiplier)
		
		# Add the effect to the scene
		caster.add_child(effect_instance)
	else:
		# If no effect scene, apply effects directly
		match utility_type:
			UtilityType.HEAL:
				caster.heal(value)
			
			UtilityType.MOVEMENT:
				_apply_movement_effect(caster, direction, value, movement_speed)
			
			UtilityType.SHIELD:
				# Temporary shield implementation if no visual effect
				if caster.has_method("add_shield"):
					caster.add_shield(value, duration)
			
			UtilityType.BUFF:
				if caster.has_method("apply_buff"):
					caster.apply_buff(value, duration, buff_multiplier)
			
			UtilityType.DEBUFF:
				# Debuffs typically apply to enemies, not the caster
				pass

func _apply_movement_effect(caster, direction: Vector2, distance: float, speed: float):
	# Create a tween to move the caster
	var tween = caster.create_tween()
	var target_position = caster.global_position + direction * distance
	var movement_time = distance / speed
	
	# Store the original collision layers
	var original_collision_layer = caster.collision_layer
	var original_collision_mask = caster.collision_mask
	
	# Temporarily disable collisions during dash
	caster.collision_layer = 0
	caster.collision_mask = 0
	
	# Move the caster
	tween.tween_property(caster, "global_position", target_position, movement_time)
	
	# Restore collision after movement
	tween.tween_callback(func():
		caster.collision_layer = original_collision_layer
		caster.collision_mask = original_collision_mask
	)

func get_description_values() -> Dictionary:
	var values = {}
	
	match utility_type:
		UtilityType.HEAL:
			values["heal_amount"] = value
		
		UtilityType.MOVEMENT:
			values["distance"] = value
			values["speed"] = movement_speed
		
		UtilityType.SHIELD:
			values["shield_amount"] = value
			values["duration"] = duration
		
		UtilityType.BUFF:
			values["buff_value"] = value
			values["buff_percent"] = int((buff_multiplier - 1.0) * 100)
			values["duration"] = duration
		
		UtilityType.DEBUFF:
			values["debuff_value"] = value
			values["debuff_percent"] = int((1.0 - debuff_multiplier) * 100)
			values["duration"] = duration
	
	return values
