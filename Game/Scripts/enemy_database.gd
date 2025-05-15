# enemy_database.gd - Manages all enemy resources
class_name EnemyDatabase
extends Node

# Dictionary of all enemies by ID
var enemies: Dictionary = {}

func _ready():
	# Load all enemy resources
	_load_all_enemies()

func _load_all_enemies():
	# Load from resources directory	
	var dir = DirAccess.open("res://Game/Resources/Enemies")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var enemy = load("res://Game/Resources/Enemies/" + file_name)
				if enemy is EnemyResource:
					enemies[enemy.id] = enemy
			file_name = dir.get_next()
	else:
		push_error("EnemyDatabase: Failed to access enemies directory")
		_create_fallback_enemies()

func _create_fallback_enemies():
	# Create basic enemy
	var basic = EnemyResource.new()
	basic.id = "basic"
	basic.name = "Forest Imp"
	basic.type = "basic"
	basic.max_health = 50
	basic.damage = 10
	basic.speed = 100.0
	basic.detection_range = 150.0
	basic.attack_range = 30.0
	basic.attack_cooldown = 1.0
	basic.score_value = 10
	enemies[basic.id] = basic
	
	# Create elite enemy
	var elite = EnemyResource.new()
	elite.id = "elite"
	elite.name = "Dark Wizard"
	elite.type = "elite"
	elite.max_health = 150
	elite.damage = 25
	elite.speed = 80.0
	elite.detection_range = 200.0
	elite.attack_range = 100.0
	elite.attack_cooldown = 2.0
	elite.score_value = 50
	enemies[elite.id] = elite
	
	# Create boss enemy
	var boss = EnemyResource.new()
	boss.id = "boss"
	boss.name = "Ancient Guardian"
	boss.type = "boss"
	boss.max_health = 500
	boss.damage = 50
	boss.speed = 60.0
	boss.detection_range = 300.0
	boss.attack_range = 150.0
	boss.attack_cooldown = 3.0
	boss.score_value = 200
	enemies[boss.id] = boss

func get_enemy(enemy_id: String) -> EnemyResource:
	if enemies.has(enemy_id):
		return enemies[enemy_id]
	push_error("EnemyDatabase: Enemy not found with ID: " + enemy_id)
	return null

func get_enemies_by_type(enemy_type: String) -> Array:
	var result = []
	for enemy_id in enemies:
		var enemy = enemies[enemy_id]
		if enemy.type == enemy_type:
			result.append(enemy)
	return result
