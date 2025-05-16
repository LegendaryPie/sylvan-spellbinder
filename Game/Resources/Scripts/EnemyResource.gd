# EnemyResource.gd - Base Enemy Resource Type
class_name EnemyResource
extends Resource

@export var id: String = ""
@export var name: String = "Enemy Name"
@export var type: String = "basic" # basic, elite, boss
@export var max_health: int = 100
@export var damage: int = 10
@export var speed: float = 100.0
@export var detection_range: float = 200.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var score_value: int = 10
@export var texture_path: String = "res://assets/enemies/default_enemy.png"

# Ranged attack properties
@export var is_ranged: bool = false
@export var projectile_speed: float = 200.0

# Optional properties
@export var special_abilities: Array[String] = []
@export var resistances: Dictionary = {}  # damage_type: resistance_percentage
@export var loot_table: Dictionary = {}   # item_id: drop_chance

func _init(p_id: String = "", p_name: String = "Enemy Name"):
	id = p_id
	name = p_name

# Create a new instance of this enemy
func create_instance() -> EnemyResource:
	return self.duplicate()
