# CardDatabase.gd - Manages all card resources
class_name CardDatabase
extends Node

# Dictionary of all cards by ID
var cards: Dictionary = {}

func _ready():
	# Load all card resources
	_load_all_cards()

func _load_all_cards():
	# Get all resource files in the cards directory
	var dir = DirAccess.open("res://Game/Resources/cards/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var card = load("res://Game/Resources/cards/" + file_name)
				if card is CardResource:
					cards[card.id] = card
			file_name = dir.get_next()
	else:
		push_error("CardDatabase: Failed to access cards directory")
		
		# Fallback: manually load some cards for testing
		_create_fallback_cards()

func _create_fallback_cards():
	# Fireball card
	var fireball = CardResource.new()
	fireball.id = "fireball"
	fireball.name = "Fireball"
	fireball.type = CardResource.CardType.ATTACK
	fireball.energy_cost = 15
	fireball.description = "Launch a fireball that deals {damage} fire damage and burns for {dot_damage} damage over {duration}s."
	fireball.texture_path = "res://assets/cards/fireball.png"
	fireball.rarity = CardResource.Rarity.COMMON
	
	var damage_effect = DamageEffectResource.new()
	damage_effect.damage = 25
	damage_effect.damage_type = "fire"
	damage_effect.is_projectile = true
	damage_effect.projectile_speed = 300
	damage_effect.projectile_range = 250
	damage_effect.effect_scene_path = "res://scenes/card_effects/FireballEffect.tscn"
	fireball.effects.append(damage_effect)
	
	var dot_effect = DamageEffectResource.new()
	dot_effect.damage = 5
	dot_effect.damage_type = "fire"
	dot_effect.is_dot = true
	dot_effect.dot_duration = 3.0
	dot_effect.dot_tick_rate = 1.0
	fireball.effects.append(dot_effect)
	
	cards[fireball.id] = fireball
	
	# Ice Spike card
	var ice_spike = CardResource.new()
	ice_spike.id = "ice_spike"
	ice_spike.name = "Ice Spike"
	ice_spike.type = CardResource.CardType.ATTACK
	ice_spike.energy_cost = 20
	ice_spike.description = "Cast an ice spike that deals {damage} ice damage and slows enemies by {debuff_percent}% for {duration}s."
	ice_spike.texture_path = "res://assets/cards/ice_spike.png"
	ice_spike.rarity = CardResource.Rarity.COMMON
	
	var ice_damage_effect = DamageEffectResource.new()
	ice_damage_effect.damage = 30
	ice_damage_effect.damage_type = "ice"
	ice_damage_effect.is_projectile = true
	ice_damage_effect.projectile_speed = 350
	ice_damage_effect.projectile_range = 300
	ice_damage_effect.effect_scene_path = "res://scenes/card_effects/IceSpikeEffect.tscn"
	ice_spike.effects.append(ice_damage_effect)
	
	var slow_effect = UtilityEffectResource.new()
	slow_effect.utility_type = UtilityEffectResource.UtilityType.DEBUFF
	slow_effect.debuff_multiplier = 0.5
	slow_effect.duration = 2.0
	ice_spike.effects.append(slow_effect)
	
	cards[ice_spike.id] = ice_spike
	
	# Healing Brew card
	var healing_brew = CardResource.new()
	healing_brew.id = "healing_brew"
	healing_brew.name = "Healing Brew"
	healing_brew.type = CardResource.CardType.UTILITY
	healing_brew.energy_cost = 25
	healing_brew.description = "Drink a potion that restores {heal_amount} health."
	healing_brew.texture_path = "res://assets/cards/healing_brew.png"
	healing_brew.rarity = CardResource.Rarity.COMMON
	
	var heal_effect = UtilityEffectResource.new()
	heal_effect.utility_type = UtilityEffectResource.UtilityType.HEAL
	heal_effect.value = 20
	heal_effect.effect_scene_path = "res://scenes/card_effects/HealEffect.tscn"
	healing_brew.effects.append(heal_effect)
	
	cards[healing_brew.id] = healing_brew
	
	# Dash card
	var dash = CardResource.new()
	dash.id = "dash"
	dash.name = "Dash"
	dash.type = CardResource.CardType.UTILITY
	dash.energy_cost = 10
	dash.description = "Quickly dash {distance} units forward, avoiding enemies."
	dash.texture_path = "res://assets/cards/dash.png"
	dash.rarity = CardResource.Rarity.COMMON
	
	var dash_effect = UtilityEffectResource.new()
	dash_effect.utility_type = UtilityEffectResource.UtilityType.MOVEMENT
	dash_effect.value = 200
	dash_effect.movement_speed = 1000
	dash_effect.effect_scene_path = "res://scenes/card_effects/DashEffect.tscn"
	dash.effects.append(dash_effect)
	
	cards[dash.id] = dash
	
	# Forest Shield card
	var forest_shield = CardResource.new()
	forest_shield.id = "forest_shield"
	forest_shield.name = "Forest Shield"
	forest_shield.type = CardResource.CardType.DEFENSE
	forest_shield.energy_cost = 20
	forest_shield.description = "Summon a shield of vines that absorbs {shield_amount} damage for {duration}s."
	forest_shield.texture_path = "res://assets/cards/forest_shield.png"
	forest_shield.rarity = CardResource.Rarity.UNCOMMON
	
	var shield_effect = UtilityEffectResource.new()
	shield_effect.utility_type = UtilityEffectResource.UtilityType.SHIELD
	shield_effect.value = 25
	shield_effect.duration = 5.0
	shield_effect.effect_scene_path = "res://scenes/card_effects/ShieldEffect.tscn"
	forest_shield.effects.append(shield_effect)
	
	cards[forest_shield.id] = forest_shield

func get_card(card_id: String) -> CardResource:
	if cards.has(card_id):
		return cards[card_id]
	else:
		push_error("CardDatabase: Card not found with ID: " + card_id)
		return null

func get_cards_by_type(card_type: CardResource.CardType) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for card_id in cards:
		var card = cards[card_id]
		if card.type == card_type:
			result.append(card)
	return result

func get_cards_by_rarity(rarity: CardResource.Rarity) -> Array[CardResource]:
	var result: Array[CardResource] = []
	for card_id in cards:
		var card = cards[card_id]
		if card.rarity == rarity:
			result.append(card)
	return result

func get_random_card() -> CardResource:
	if cards.size() > 0:
		var keys = cards.keys()
		var random_index = randi() % keys.size()
		return cards[keys[random_index]]
	return null

func get_random_card_by_rarity(rarity: CardResource.Rarity) -> CardResource:
	var filtered_cards = get_cards_by_rarity(rarity)
	if filtered_cards.size() > 0:
		return filtered_cards[randi() % filtered_cards.size()]
	return null
