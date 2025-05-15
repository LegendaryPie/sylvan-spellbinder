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
var current_state: int = State.IDLE
var attack_timer: float = 0.0

enum State {
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

func _handle_idle_state(_delta):
	velocity = Vector2.ZERO
	if target:
		current_state = State.CHASE

func _handle_chase_state(_delta):
	if not target:
		current_state = State.IDLE
		return
	
	var distance_to_target = global_position.distance_to(target.global_position)
	
	# Move towards target only if outside attack range + small buffer
	if distance_to_target > resource.attack_range + 10.0:
		# Move towards target
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * resource.speed
	else:
		# If we're too close, slightly back away
		velocity = (global_position - target.global_position).normalized() * (resource.speed * 0.5)
	
	# Check if in attack range
	if distance_to_target <= resource.attack_range:
		current_state = State.ATTACK
		attack_timer = 0.0

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
	# Implement stun duration and recovery

func _perform_attack():
	if target and target.has_method("take_damage"):
		target.take_damage(resource.damage)

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
	print("Mouse entered enemy: ", resource.name if resource else "Unknown")
	if name_label and resource and resource.type != "boss":
		name_label.visible = true
		print("Showing name label for: ", resource.name)

func _on_mouse_exited():
	print("Mouse exited enemy: ", resource.name if resource else "Unknown")
	if name_label and resource and resource.type != "boss":
		name_label.visible = false
		print("Hiding name label for: ", resource.name)
