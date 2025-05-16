# enemy_manager.gd - Manages enemy spawning and state
class_name EnemyManager
extends Node2D

signal enemy_spawned(enemy)
signal enemy_died(enemy)

# Spawn settings
@export var max_enemies: int = 10
@export var spawn_interval: float = 5.0
@export var spawn_points: Array[Node] = []
@export var enemy_scene: PackedScene
@export var constant_spawning: bool = false

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
	if constant_spawning and active_enemies.size() < max_enemies:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_enemy()
			spawn_timer = 0.0

func spawn_enemy(enemy_resource : EnemyResource = null, enemy_type : String = ""):
	if not enemy_scene or spawn_points.is_empty():
		return
	
	if !enemy_type and !enemy_resource:
		# Select enemy type based on weights
		enemy_type = _select_enemy_type()
		var enemy_of_type = enemy_database.get_enemies_by_type(enemy_type)
		enemy_resource = enemy_of_type[randi() % enemy_of_type.size()]
	elif enemy_type and !enemy_resource:
		var enemy_of_type = enemy_database.get_enemies_by_type(enemy_type)
		enemy_resource = enemy_of_type[randi() % enemy_of_type.size()]
	
	if enemy_resource:
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.resource = enemy_resource
		
		# Find a valid spawn point that's not too close to the player or other enemies
		var spawn_point = _get_valid_spawn_point()
		if spawn_point:
			add_child(enemy_instance)
			enemy_instance.global_position = spawn_point.global_position
			enemy_instance.died.connect(_on_enemy_died)
			active_enemies.append(enemy_instance)
			emit_signal("enemy_spawned", enemy_instance)

func _get_valid_spawn_point() -> Node:
	var player = get_tree().get_first_node_in_group("player")
	if !player:
		return spawn_points[randi() % spawn_points.size()]
	
	var min_distance_to_player = 100.0  # Minimum distance from player
	var min_distance_between_enemies = 50.0  # Minimum distance between enemies
	var valid_points = []
	
	for point in spawn_points:
		var too_close = false
		
		# Check distance to player
		if player.global_position.distance_to(point.global_position) < min_distance_to_player:
			continue
		
		# Check distance to other enemies
		for enemy in active_enemies:
			if enemy.global_position.distance_to(point.global_position) < min_distance_between_enemies:
				too_close = true
				break
		
		if !too_close:
			valid_points.append(point)
	
	if valid_points.is_empty():
		# If no valid points found, use any spawn point as fallback
		return spawn_points[randi() % spawn_points.size()]
	
	return valid_points[randi() % valid_points.size()]

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
	
func clear_enemies():
	for enemy in active_enemies:
		enemy._die()
		
func get_enemy_count():
	return len(active_enemies)

