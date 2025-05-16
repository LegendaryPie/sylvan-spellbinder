# ArtifactManager.gd - Manages artifacts for the player
class_name ArtifactManager
extends Node

signal artifact_added(artifact: ArtifactResource)
signal artifact_removed(artifact: ArtifactResource)

var artifacts: Array[ArtifactResource] = []
@onready var artifact_database = get_node("../ArtifactDatabase")

func _ready():
	# Connect to relevant signals
	Events.connect("room_entered", _on_room_entered)
	Events.connect("card_played", _on_card_played)
	Events.connect("player_hit", _on_player_hit)
	Events.connect("enemy_killed", _on_enemy_killed)

func add_artifact(artifact: ArtifactResource) -> void:
	artifacts.append(artifact)
	emit_signal("artifact_added", artifact)
	Events.emit_signal("artifact_effect_triggered", artifact, "obtained")
	
	# Apply immediate effects
	var player = get_parent()
	if player:
		if artifact.health_bonus != 0:
			player.max_health += artifact.health_bonus
			player.health = min(player.health + artifact.health_bonus, player.max_health)
			Events.emit_signal("artifact_effect_triggered", artifact, "health")
		
		if artifact.energy_bonus != 0:
			player.max_energy += artifact.energy_bonus
			player.energy = min(player.energy + artifact.energy_bonus, player.max_energy)
			Events.emit_signal("artifact_effect_triggered", artifact, "energy")

func remove_artifact(artifact: ArtifactResource) -> void:
	var idx = artifacts.find(artifact)
	if idx != -1:
		artifacts.remove_at(idx)
		emit_signal("artifact_removed", artifact)
		Events.emit_signal("artifact_effect_triggered", artifact, "removed")
		
		# Remove effects
		var player = get_parent()
		if player:
			player.max_health -= artifact.health_bonus
			player.health = min(player.health, player.max_health)
			player.max_energy -= artifact.energy_bonus
			player.energy = min(player.energy, player.max_energy)

func modify_damage(base_damage: float) -> float:
	var final_damage = base_damage
	for artifact in artifacts:
		final_damage = artifact.modify_damage(final_damage)
	return final_damage

func modify_healing(base_healing: float) -> float:
	var final_healing = base_healing
	for artifact in artifacts:
		final_healing = artifact.modify_healing(final_healing)
	return final_healing

func modify_shield(base_shield: float) -> float:
	var final_shield = base_shield
	for artifact in artifacts:
		final_shield = artifact.modify_shield(final_shield)
	return final_shield

func modify_card_cost(base_cost: int) -> int:
	var final_cost = base_cost
	for artifact in artifacts:
		final_cost = artifact.modify_card_cost(final_cost)
	return final_cost

func get_health_bonus() -> int:
	var bonus = 0
	for artifact in artifacts:
		bonus += artifact.health_bonus
	return bonus

func get_energy_bonus() -> int:
	var bonus = 0
	for artifact in artifacts:
		bonus += artifact.energy_bonus
	return bonus

func get_card_draw_bonus() -> int:
	var bonus = 0
	for artifact in artifacts:
		bonus += artifact.card_draw_bonus
	return bonus

func _on_room_entered(room):
	for artifact in artifacts:
		if artifact.triggers_on_room_entry:
			artifact.on_room_entry(get_parent())
			Events.emit_signal("artifact_effect_triggered", artifact, "room_entry")

func _on_card_played(card):
	for artifact in artifacts:
		if artifact.triggers_on_card_play:
			artifact.on_card_played(get_parent(), card)
			Events.emit_signal("artifact_effect_triggered", artifact, "card_play")

func _on_player_hit(damage_info):
	for artifact in artifacts:
		if artifact.triggers_on_hit:
			artifact.on_hit(get_parent(), damage_info)
			Events.emit_signal("artifact_effect_triggered", artifact, "hit")

func _on_enemy_killed(enemy):
	for artifact in artifacts:
		if artifact.triggers_on_kill:
			artifact.on_kill(get_parent(), enemy)
			Events.emit_signal("artifact_effect_triggered", artifact, "kill")

# For saving/loading
func get_save_data() -> Dictionary:
	var data = {
		"artifacts": []
	}
	
	for artifact in artifacts:
		data.artifacts.append(artifact.id)
	
	return data

func load_save_data(data: Dictionary) -> void:
	artifacts.clear()
	
	if data.has("artifacts") and artifact_database:
		for artifact_id in data.artifacts:
			var artifact = artifact_database.get_artifact(artifact_id)
			if artifact:
				add_artifact(artifact)
