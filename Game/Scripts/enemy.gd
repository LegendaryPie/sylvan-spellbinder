# enemy.gd - Basic Enemy Implementation
class_name Enemy
extends CharacterBody2D

signal died(enemy)
signal health_changed(current, maximum)

@export var resource: EnemyResource

# State variables
var health: int = 100
var is_dead: bool = false
var target: Node2D = null
var current_state: int = State.SPAWNING
var attack_timer: float = 0.0
var spawn_timer: float = 0.5  # Time before enemy becomes active

# Idle movement variables
var idle_direction: Vector2 = Vector2.ZERO
var idle_timer: float = 0.0
var idle_wait_time: float = 2.0  # Time to wait between movements
var idle_move_time: float = 1.5  # Time to move in a direction
var is_idle_moving: bool = false
var spawn_position: Vector2  # Store initial position for wandering radius

# Projectile variables
var projectile_scene: PackedScene = null

enum State {
	SPAWNING,
	IDLE,
	CHASE,
	ATTACK,
	STUNNED
}

# Node references
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var hit_box = $HitBox
@onready var detection_area = $DetectionArea
@onready var name_label = $NameLabel
@onready var health_bar = $HealthBar

func _ready():
	if resource:
		_initialize_from_resource()
	
	# Store initial spawn position for wandering radius
	spawn_position = global_position
	
	# Start in spawning state with detection disabled
	current_state = State.SPAWNING
	if detection_area:
		detection_area.monitoring = false
		detection_area.monitorable = false
	
	# Connect areas
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	hit_box.area_entered.connect(_on_hit_box_area_entered)
	
	# Set up mouse hover detection
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Initialize name label and health bar
	if name_label:
		name_label.text = resource.name if resource else "Enemy"
		name_label.visible = resource and resource.type == "boss"
		
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health
		health_bar.modulate = Color(1, 0, 0)  # Red health bar
	
	# Load projectile scene if this is a ranged enemy type
	if resource and "is_ranged" in resource and resource.is_ranged:
		projectile_scene = load("res://Game/Scenes/projectile.tscn")
		if not projectile_scene:
			push_error("Enemy: Failed to load projectile scene")

func _initialize_from_resource():
	health = resource.max_health
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health
	
	# Set up collision shapes
	var detection_shape = $DetectionArea/CollisionShape2D
	if detection_shape:
		detection_shape.shape.radius = resource.detection_range
	
	var hit_shape = $HitBox/CollisionShape2D
	if hit_shape:
		hit_shape.shape.radius = resource.attack_range
	
	# Load texture
	if ResourceLoader.exists(resource.texture_path):
		sprite.texture = load(resource.texture_path)

func _physics_process(delta):
	if is_dead:
		return
	
	if current_state == State.SPAWNING:
		spawn_timer -= delta
		if spawn_timer <= 0:
			current_state = State.IDLE
			if detection_area:
				detection_area.monitoring = true
				detection_area.monitorable = true
		return
	
	match current_state:
		State.IDLE:
			_handle_idle_state(delta)
		State.CHASE:
			_handle_chase_state(delta)
		State.ATTACK:
			_handle_attack_state(delta)
		State.STUNNED:
			_handle_stunned_state(delta)
	
	# Apply movement
	var collision = move_and_slide()
	
	# Handle collision pushback
	if collision:
		for i in get_slide_collision_count():
			var collision_obj = get_slide_collision(i)
			if collision_obj.get_collider().is_in_group("player"):
				# Add a small pushback when colliding with player
				global_position += collision_obj.get_normal() * 5.0

func _handle_idle_state(delta):
	if target:
		current_state = State.CHASE
		return
		
	if is_idle_moving:
		# Continue moving in the current direction
		velocity = idle_direction * (resource.speed * 0.5)  # Move at half speed while idle
		
		# Check if we've wandered too far from spawn point
		var distance_from_spawn = global_position.distance_to(spawn_position)
		if distance_from_spawn > resource.detection_range * 0.5:
			# Turn around and head back to spawn
			idle_direction = (spawn_position - global_position).normalized()
		
		idle_timer -= delta
		if idle_timer <= 0:
			# Stop moving and wait
			is_idle_moving = false
			idle_timer = idle_wait_time
			velocity = Vector2.ZERO
	else:
		# Waiting phase, decrease timer
		idle_timer -= delta
		if idle_timer <= 0:
			# Change direction and start moving
			idle_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			is_idle_moving = true
			idle_timer = idle_move_time

func _handle_chase_state(_delta):
	if not target:
		current_state = State.IDLE
		return
	
	var distance_to_target = global_position.distance_to(target.global_position)
	var direction = (target.global_position - global_position).normalized()
	
	# Get overlapping enemies for collision avoidance
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.collision_mask = 2  # Enemy layer
	query.transform = Transform2D(0, global_position)
	query.shape = CircleShape2D.new()
	query.shape.radius = 30.0  # Collision avoidance radius
	
	var nearby = space_state.intersect_shape(query)
	var avoid_vector = Vector2.ZERO
	
	# Calculate avoidance vector based on nearby enemies
	for result in nearby:
		var other = result["collider"]
		if other != self and other is CharacterBody2D:
			var to_other = global_position - other.global_position
			if to_other.length() > 0:
				avoid_vector += to_other.normalized() / to_other.length()
	
	# For ranged enemies, maintain distance
	if resource and "is_ranged" in resource and resource.is_ranged:
		var ideal_range = resource.attack_range * 0.8
		if distance_to_target < ideal_range:
			# Back away from target
			direction = (global_position - target.global_position).normalized()
			velocity = (direction + avoid_vector).normalized() * resource.speed
		elif distance_to_target > resource.attack_range:
			# Move closer to target
			velocity = (direction + avoid_vector).normalized() * resource.speed
		else:
			velocity = avoid_vector.normalized() * resource.speed * 0.5
			if avoid_vector.length_squared() < 0.1:
				velocity = Vector2.ZERO
				current_state = State.ATTACK
	else:
		# Melee enemy behavior
		if distance_to_target > resource.attack_range:
			# Move towards target
			velocity = (direction + avoid_vector).normalized() * resource.speed
		else:
			velocity = avoid_vector.normalized() * resource.speed * 0.5
			if avoid_vector.length_squared() < 0.1:
				velocity = Vector2.ZERO
				current_state = State.ATTACK

func _handle_attack_state(delta):
	velocity = Vector2.ZERO
	
	if not target or global_position.distance_to(target.global_position) > resource.attack_range:
		current_state = State.CHASE
		return
	
	attack_timer += delta
	if attack_timer >= resource.attack_cooldown:
		_perform_attack()
		attack_timer = 0.0

func _handle_stunned_state(_delta):
	velocity = Vector2.ZERO

func _handle_idle_movement(delta):
	if is_idle_moving:
		# Continue moving in the current direction
		velocity = idle_direction * resource.speed
		
		idle_timer -= delta
		if idle_timer <= 0:
			# Stop moving and wait
			is_idle_moving = false
			idle_timer = idle_wait_time
	else:
		# Waiting phase, decrease timer
		idle_timer -= delta
		if idle_timer <= 0:
			# Change direction and start moving
			idle_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			is_idle_moving = true
			idle_timer = idle_move_time

func _perform_attack():
	if not target:
		return
		
	if resource and "is_ranged" in resource and resource.is_ranged:
		_shoot_projectile()
	else:
		if target.has_method("take_damage"):
			target.take_damage(resource.damage)

func _shoot_projectile():
	if not projectile_scene or not target:
		return
		
	var projectile = projectile_scene.instantiate()
	if projectile:
		# Add projectile to the scene
		get_tree().current_scene.add_child(projectile)
		
		# Calculate direction to target
		var direction = (target.global_position - global_position).normalized()
		
		# Initialize projectile
		projectile.initialize(
			global_position,
			direction,
			resource.damage
		)  # Position, direction, damage

func take_damage(amount: int):
	if is_dead:
		return
		
	health = max(0, health - amount)
	
	if health_bar:
		health_bar.value = health
	
	# Visual feedback
	_flash_damage()
	
	if health <= 0:
		_die()
	else:
		emit_signal("health_changed", health, resource.max_health if resource else 100)

func _flash_damage():
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 0, 0), 0.1)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)

func _die():
	is_dead = true
	emit_signal("died", self)
	
	# Play death animation or effect
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		target = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body):
	if body == target:
		target = null
		current_state = State.IDLE

func _on_hit_box_area_entered(area: Area2D):
	if area.has_method("get_damage"):
		take_damage(area.get_damage())

func _on_mouse_entered():
	if name_label and resource and resource.type != "boss":
		name_label.visible = true

func _on_mouse_exited():
	if name_label and resource and resource.type != "boss":
		name_label.visible = false
