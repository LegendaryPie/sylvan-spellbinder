# enemy_manager.gd - Manages enemy spawning and state
class_name EnemyManager
extends Node

signal enemy_spawned(enemy)
signal enemy_died(enemy)

# Spawn settings
@export var max_enemies: int = 10
@export var spawn_interval: float = 5.0
@export var spawn_points: Array[Node] = []
@export var enemy_scene: PackedScene

# Enemy type weights for spawning (id: weight)
@export var enemy_weights: Dictionary = {
	"basic": 70,
	"elite": 25,
	"boss": 5
}

var active_enemies: Array[Enemy] = []
var spawn_timer: float = 0.0
var total_weight: int = 0

# Reference to enemy database
@onready var enemy_database = $EnemyDatabase

func _ready():
	# Calculate total weight for random selection
	for weight in enemy_weights.values():
		total_weight += weight

func _physics_process(delta):
	if active_enemies.size() < max_enemies:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_enemy()
			spawn_timer = 0.0

func spawn_enemy():
	if not enemy_scene or spawn_points.is_empty():
		return
	
	# Select random spawn point
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	
	# Select enemy type based on weights
	var enemy_type = _select_enemy_type()
	var enemy_resource = enemy_database.get_enemy(enemy_type)
	
	if enemy_resource:
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.resource = enemy_resource
		
		# Position at spawn point
		enemy_instance.global_position = spawn_point.global_position
		
		# Connect signals
		enemy_instance.died.connect(_on_enemy_died)
		
		# Add to scene
		add_child(enemy_instance)
		active_enemies.append(enemy_instance)
		
		emit_signal("enemy_spawned", enemy_instance)

func _select_enemy_type() -> String:
	var roll = randi() % total_weight
	var current_weight = 0
	
	for enemy_type in enemy_weights:
		current_weight += enemy_weights[enemy_type]
		if roll < current_weight:
			return enemy_type
	
	return "basic"  # Fallback

func _on_enemy_died(enemy: Enemy):
	active_enemies.erase(enemy)
	emit_signal("enemy_died", enemy)
