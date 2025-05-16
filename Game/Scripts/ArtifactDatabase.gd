# ArtifactDatabase.gd - Database for all artifacts in the game
class_name ArtifactDatabase
extends Node

var artifacts: Dictionary = {}  # id -> ArtifactResource

func _ready():
	_load_all_artifacts()

func _load_all_artifacts():
	# Clear existing artifacts
	artifacts.clear()
	
	# Create some example artifacts for each rarity
	
	# NORMAL artifacts
	# Basic health artifact
	var LifeGemArtifact = load("res://Game/Resources/Scripts/Artifacts/LifeGemArtifact.gd")
	var life_gem = LifeGemArtifact.new()
	life_gem.id = "life_gem"
	life_gem.name = "Life Gem"
	life_gem.description = "Increase maximum health by 25. Heal for 5 when entering a room."
	life_gem.rarity = ArtifactResource.Rarity.NORMAL
	life_gem.health_bonus = 25
	life_gem.triggers_on_room_entry = true
	life_gem.trigger_effect_color = Color(0.0, 1.0, 0.0, 0.5)
	artifacts[life_gem.id] = life_gem
	
	# Basic energy artifact
	var MysticRingArtifact = load("res://Game/Resources/Scripts/Artifacts/MysticRingArtifact.gd")
	var mystic_ring = MysticRingArtifact.new()
	mystic_ring.id = "mystic_ring"
	mystic_ring.name = "Mystic Ring"
	mystic_ring.description = "Increase maximum energy by 1. The first card played each room costs 1 less."
	mystic_ring.rarity = ArtifactResource.Rarity.NORMAL
	mystic_ring.energy_bonus = 1
	mystic_ring.triggers_on_room_entry = true
	mystic_ring.triggers_on_card_play = true
	artifacts[mystic_ring.id] = mystic_ring
			
	# Shield on damage artifact
	var ReactiveWardArtifact = load("res://Game/Resources/Scripts/Artifacts/ReactiveWardArtifact.gd")
	var reactive_ward = ReactiveWardArtifact.new()
	reactive_ward.id = "reactive_ward"
	reactive_ward.name = "Reactive Ward"
	reactive_ward.description = "When hit, gain 5 shield"
	reactive_ward.rarity = ArtifactResource.Rarity.NORMAL
	reactive_ward.triggers_on_hit = true
	reactive_ward.trigger_effect_color = Color(0.4, 0.7, 1.0)
	reactive_ward.trigger_effect_particles = true
	artifacts[reactive_ward.id] = reactive_ward
	
	# ELITE artifacts
	var CombatFocusArtifact = load("res://Game/Resources/Scripts/Artifacts/CombatFocusArtifact.gd")
	var combat_focus = CombatFocusArtifact.new()
	combat_focus.id = "combat_focus"
	combat_focus.name = "Combat Focus"
	combat_focus.description = "All attacks deal 20% more damage. Your first attack each room deals double damage."
	combat_focus.rarity = ArtifactResource.Rarity.ELITE
	combat_focus.damage_multiplier = 1.2
	combat_focus.triggers_on_room_entry = true
	combat_focus.triggers_on_card_play = true
	combat_focus.trigger_effect_color = Color(1.0, 0.5, 0.0)
	artifacts[combat_focus.id] = combat_focus
	
	var ManaWeaverArtifact = load("res://Game/Resources/Scripts/Artifacts/ManaWeaverArtifact.gd")
	var mana_weaver = ManaWeaverArtifact.new()
	mana_weaver.id = "mana_weaver"
	mana_weaver.name = "Mana Weaver"
	mana_weaver.description = "All spells cost 1 less energy. Each room starts with a random card costing 0."
	mana_weaver.rarity = ArtifactResource.Rarity.ELITE
	mana_weaver.energy_cost_reduction = 1
	mana_weaver.triggers_on_room_entry = true
	mana_weaver.trigger_effect_color = Color(0.5, 0.0, 1.0)
	mana_weaver.trigger_effect_particles = true
	artifacts[mana_weaver.id] = mana_weaver
			
	var BerserkerPendantArtifact = load("res://Game/Resources/Scripts/Artifacts/BerserkerPendantArtifact.gd")
	var berserker_pendant = BerserkerPendantArtifact.new()
	berserker_pendant.id = "berserker_pendant"
	berserker_pendant.name = "Berserker's Pendant"
	berserker_pendant.description = "When below 50% health, deal 50% more damage"
	berserker_pendant.rarity = ArtifactResource.Rarity.ELITE
	berserker_pendant.triggers_on_card_play = true
	berserker_pendant.trigger_effect_color = Color(1.0, 0.0, 0.0)
	artifacts[berserker_pendant.id] = berserker_pendant
	
	# TREASURE artifacts	
	var HealingChaliceArtifact = load("res://Game/Resources/Scripts/Artifacts/HealingChaliceArtifact.gd")
	var healing_chalice = HealingChaliceArtifact.new()
	healing_chalice.id = "healing_chalice"
	healing_chalice.name = "Healing Chalice"
	healing_chalice.description = "Healing is 50% more effective. Upon entering a room, heal 2 for each card in your hand."
	healing_chalice.rarity = ArtifactResource.Rarity.TREASURE
	healing_chalice.heal_multiplier = 1.5
	healing_chalice.triggers_on_room_entry = true
	healing_chalice.trigger_effect_color = Color(1.0, 0.8, 0.8)
	healing_chalice.trigger_effect_particles = true
	artifacts[healing_chalice.id] = healing_chalice
	var ArcaneShieldArtifact = load("res://Game/Resources/Scripts/Artifacts/ArcaneShieldArtifact.gd")
	var arcane_shield = ArcaneShieldArtifact.new()
	arcane_shield.id = "arcane_shield"
	arcane_shield.name = "Arcane Shield"
	arcane_shield.description = "Shields are 50% more powerful. The first hit each room is completely blocked."
	arcane_shield.rarity = ArtifactResource.Rarity.TREASURE
	arcane_shield.shield_multiplier = 1.5
	arcane_shield.triggers_on_room_entry = true
	arcane_shield.triggers_on_hit = true
	arcane_shield.trigger_effect_color = Color(0.0, 0.5, 1.0)
	arcane_shield.trigger_effect_particles = true
	artifacts[arcane_shield.id] = arcane_shield
	
	var MageKingsStaffArtifact = load("res://Game/Resources/Scripts/Artifacts/MageKingsStaffArtifact.gd")
	var mage_kings_staff = MageKingsStaffArtifact.new()
	mage_kings_staff.id = "mage_kings_staff"
	mage_kings_staff.name = "Mage-King's Staff"
	mage_kings_staff.description = "Upon entering a room, your most expensive card in hand costs 0 this combat"
	mage_kings_staff.rarity = ArtifactResource.Rarity.TREASURE
	mage_kings_staff.triggers_on_room_entry = true
	mage_kings_staff.trigger_effect_color = Color(0.5, 0.0, 1.0)
	mage_kings_staff.trigger_effect_particles = true
	artifacts[mage_kings_staff.id] = mage_kings_staff
	
	# BOSS artifacts	
	var AncientCrownArtifact = load("res://Game/Resources/Scripts/Artifacts/AncientCrownArtifact.gd")
	var ancient_crown = AncientCrownArtifact.new()
	ancient_crown.id = "ancient_crown"
	ancient_crown.name = "Ancient Crown"
	ancient_crown.description = "Draw 1 additional card each turn and start each room with 1 additional energy"
	ancient_crown.rarity = ArtifactResource.Rarity.BOSS
	ancient_crown.card_draw_bonus = 1
	ancient_crown.triggers_on_room_entry = true
	ancient_crown.trigger_effect_color = Color(1.0, 0.8, 0.0)
	ancient_crown.trigger_sound_effect = "res://Assets/Sounds/crown_effect.wav"
	artifacts[ancient_crown.id] = ancient_crown
	var BattleTranceArtifact = load("res://Game/Resources/Scripts/Artifacts/BattleTranceArtifact.gd")
	var battle_trance = BattleTranceArtifact.new()
	battle_trance.id = "battle_trance"
	battle_trance.name = "Battle Trance"
	battle_trance.description = "Upon killing an enemy, gain 5 health and 1 energy. Deal 2 more damage with all attacks."
	battle_trance.rarity = ArtifactResource.Rarity.BOSS
	battle_trance.triggers_on_kill = true
	battle_trance.damage_bonus = 2.0
	battle_trance.trigger_effect_color = Color(1.0, 0.0, 0.0)
	battle_trance.trigger_effect_particles = true
	battle_trance.trigger_sound_effect = "res://Assets/Sounds/battle_trance.wav"
	artifacts[battle_trance.id] = battle_trance

func get_artifact(id: String) -> ArtifactResource:
	if artifacts.has(id):
		return artifacts[id].create_instance()
	return null

func get_random_artifact(rarity: ArtifactResource.Rarity = ArtifactResource.Rarity.NORMAL) -> ArtifactResource:
	var matching_artifacts = []
	
	for artifact in artifacts.values():
		if artifact.rarity == rarity:
			matching_artifacts.append(artifact)
	
	if matching_artifacts.size() > 0:
		var random_index = randi() % matching_artifacts.size()
		return matching_artifacts[random_index].create_instance()
	
	return null
