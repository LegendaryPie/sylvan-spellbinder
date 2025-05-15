extends Area2D
class_name DamageEffect

var damage: int = 0
var damage_type: String = "physical"
var duration: float = 0.0
var tick_interval: float = 0.0
var tick_timer: float = 0.0
var total_time: float = 0.0
var has_hit: bool = false

# Projectile properties
var is_projectile: bool = false
var projectile_direction: Vector2 = Vector2.ZERO
var projectile_speed: float = 0.0
var projectile_range: float = 0.0
var distance_traveled: float = 0.0

func _ready():
	# Set up collision detection
	collision_layer = 4  # Spell effects layer
	collision_mask = 2   # Enemy layer
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	area_shape_entered.connect(_on_area_shape_entered)

func set_damage(value: int):
	damage = value

func set_damage_type(type: String):
	damage_type = type

func set_dot_properties(time: float, interval: float):
	duration = time
	tick_interval = interval

func set_area_properties(radius: float):
	# Update collision shape
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		var circle = collision_shape.shape as CircleShape2D
		if circle:
			circle.radius = radius

func set_projectile_properties(direction: Vector2, speed: float, travel_range: float):
	is_projectile = true
	projectile_direction = direction.normalized()
	projectile_speed = speed
	projectile_range = travel_range
	distance_traveled = 0.0

func _physics_process(delta):
	if is_projectile:
		var movement = projectile_direction * projectile_speed * delta
		global_position += movement
		distance_traveled += movement.length()
		
		if distance_traveled >= projectile_range:
			queue_free()
			return
	
	# Handle DoT effects
	if duration > 0:
		total_time += delta
		tick_timer += delta
		
		if tick_timer >= tick_interval:
			tick_timer = 0
			_apply_damage()
		
		if total_time >= duration:
			queue_free()
	elif !has_hit and !is_projectile:
		# For instant effects (non-projectile, non-DoT), apply damage once and cleanup
		_apply_damage()
		has_hit = true
		queue_free()

func _apply_damage():
	print("Applying damage: ", damage)  # Debug print
	# Check for overlapping areas
	var overlapping_areas = get_overlapping_areas()
	for area in overlapping_areas:
		print("Found overlapping area: ", area.name)  # Debug print
		if area.is_in_group("enemy_hurtbox"):
			var enemy = area.get_parent()
			if enemy and enemy.has_method("take_damage"):
				print("Dealing damage to enemy: ", enemy.name)  # Debug print
				enemy.take_damage(damage)

func get_damage() -> int:
	return damage

func _on_area_entered(area: Area2D):
	if area.get_parent() and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)

func _on_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int):
	if area.get_parent() and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)
