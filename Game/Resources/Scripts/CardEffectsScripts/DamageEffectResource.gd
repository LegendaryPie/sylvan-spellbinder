# DamageEffectResource.gd - Damage Effect Resource Type
class_name DamageEffectResource
extends CardEffectResource

@export var damage: int = 10
@export var damage_type: String = "physical" # physical, fire, ice, poison, lightning
@export var is_area_effect: bool = false
@export var radius: float = 0.0 # For area effects
@export var is_dot: bool = false # Damage over time
@export var tick_interval: float = 1.0 # For DOT effects
@export var is_projectile: bool = false
@export var projectile_speed: float = 300
@export var projectile_range: float = 500
@export var chain_targets: int = 0 # For chain effects like lightning
@export var chain_range: float = 0.0 # For chain effects

func _init():
	effect_type = "damage"

func execute(caster, target_position: Vector2, direction: Vector2):
	# Set default effect scene if none is specified
	if effect_scene_path.is_empty():
		effect_scene_path = "res://Game/Scenes/spell_effects/fireball_effect.tscn"
	
	# Verify scene exists
	if not FileAccess.file_exists(effect_scene_path.replace("res://", "").replace("/", "\\")):
		push_error("DamageEffectResource: Effect scene not found at " + effect_scene_path)
		return
	
	var effect_scene = load(effect_scene_path)
	var effect_instance = effect_scene.instantiate()
	
	# Configure the effect based on properties
	effect_instance.set_damage(damage)
	effect_instance.set_damage_type(damage_type)
	
	# Handle different effect types
	if is_projectile:
		effect_instance.set_projectile_properties(direction, projectile_speed, projectile_range)
	elif is_area_effect:
		effect_instance.set_area_properties(radius)
	
	if is_dot:
		effect_instance.set_dot_properties(duration, tick_interval)
	
	if chain_targets > 0:
		effect_instance.set_chain_properties(chain_targets, chain_range)
	
	# Add the effect to the scene
	if caster.get_parent():
		caster.get_parent().add_child(effect_instance)
	else:
		caster.get_tree().current_scene.add_child(effect_instance)
	
	# Position the effect
	if is_projectile:
		# Start projectile from slightly in front of the caster
		effect_instance.global_position = caster.global_position + direction * 30
	elif is_area_effect:
		effect_instance.global_position = target_position
		# Show area of effect briefly before cleanup
		var tween = effect_instance.create_tween()
		tween.tween_property(effect_instance, "modulate:a", 0.0, 0.3)
		tween.tween_callback(effect_instance.queue_free)
	else:
		effect_instance.global_position = caster.global_position

func get_description_values() -> Dictionary:
	var values = {
		"damage": damage
	}
	
	if is_dot:
		values["duration"] = duration
		values["total_damage"] = damage * (duration / tick_interval)
	
	if is_area_effect:
		values["radius"] = radius
	
	if chain_targets > 0:
		values["chain_targets"] = chain_targets
	
	return values
