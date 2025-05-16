class_name Projectile
extends Area2D

@export var speed: float = 200.0  # Default speed
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.ZERO
var time_alive: float = 0.0

func _ready():
	# Connect collision signal
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Move projectile
	position += direction * speed * delta
	
	# Handle lifetime
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_area_entered(area: Area2D):
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)
		queue_free()

func _on_body_entered(_body: Node2D):
	queue_free()

func get_damage() -> int:
	return damage

func initialize(pos: Vector2, dir: Vector2, dmg: int = 10):
	position = pos
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()
