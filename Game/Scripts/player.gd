extends CharacterBody2D
class_name Player

# Movement properties
@export var speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1000.0

# Character stats
@export var max_health: int = 100
@export var max_energy: float = 100.0
@export var energy_regen_rate: float = 15.0

# Card system variables
@export var max_hand_size: int = 5
@export var cards_per_draw: int = 1
@export var draw_cooldown: float = 1.0
var can_draw: bool = true
var draw_timer: float = 0.0

# State variables
var health: int
var energy: float
var is_dead: bool = false
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0
@export var invulnerability_duration: float = 0.5
var shield_amount: int = 0

# Targeting system variables
var is_targeting: bool = false
var targeting_card_index: int = -1
var targeting_card: CardResource = null
var targeting_radius: float = 0.0
var targeting_max_range: float = 500.0

# Visual targeting system nodes
@onready var targeting_sprite = $TargetingArea/TargetingSprite

# References to other nodes
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var card_manager = $CardDeckManager
@onready var hurt_box = $HurtBox
@onready var targeting_area = $TargetingArea

func _ready():
	# Initialize character
	health = max_health
	energy = max_energy
	
	# Connect signals
	hurt_box.connect("area_entered", Callable(self, "_on_hurt_box_area_entered"))
	Events.card_clicked.connect(_on_card_clicked)
	
	# Initialize targeting system
	_setup_targeting_system()

func _physics_process(delta):
	if is_dead:
		return
		
	_handle_movement(delta)
	_handle_energy_regen(delta)
	_handle_invulnerability(delta)
	_handle_card_draw_cooldown(delta)

func _handle_movement(delta):
	# Get input direction
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	input_direction = input_direction.normalized()
	
	# Apply acceleration and friction
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
		_update_animation(input_direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		_play_animation("idle")
	
	# Move the character
	move_and_slide()

func _update_animation(direction):
	# Update character animations based on movement direction
	if abs(direction.x) > abs(direction.y):
		# Horizontal movement
		if direction.x > 0:
			_play_animation("walk_right")
		else:
			_play_animation("walk_left")
	else:
		# Vertical movement or diagonal where vertical component is larger
		if direction.y > 0:
			_play_animation("walk_down")
		else:
			_play_animation("walk_up")

func _play_animation(anim_name):
	if animation_player and animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

func _handle_energy_regen(delta):
	if energy < max_energy:
		energy = min(energy + energy_regen_rate * delta, max_energy)
		_emit_energy_changed()

func _handle_card_draw_cooldown(delta):
		draw_timer += delta
		if draw_timer >= draw_cooldown:
			for i in range(cards_per_draw):
				var drawn = card_manager.draw_card()
				if not drawn:
					break
				draw_timer = 0.0

func _handle_invulnerability(delta):
	if is_invulnerable:
		invulnerability_timer += delta
		# Flash the sprite to indicate invulnerability
		if int(invulnerability_timer * 10) % 2 == 0:
			sprite.modulate.a = 0.5
		else:
			sprite.modulate.a = 1.0
			
		if invulnerability_timer >= invulnerability_duration:
			is_invulnerable = false
			invulnerability_timer = 0.0
			sprite.modulate.a = 1.0

func play_card(card_index: int) -> bool:
	if card_index < 0:
		return false
		
	var card = card_manager.get_card_at(card_index)
	if not card:
		return false
	
	# Check if we have enough energy
	if energy < card.energy_cost:
		return false
	
	# Check if card needs targeting
	# Cards need targeting if they're attack type or have effects with targeting
	var needs_targeting = card.type == "attack"
	var max_range = 500.0  # Default max range
	targeting_radius = 30.0  # Default radius
	
	for effect in card.effects:
		if effect is DamageEffectResource:
			needs_targeting = true
			targeting_radius = effect.radius if effect.radius > 0 else 30.0
			# Set range based on effect type
			if effect.is_projectile:
				max_range = effect.projectile_range
			elif effect.is_area_effect:
				max_range = 200.0  # Melee range for area effects
			break
	
	if needs_targeting:
		# Start targeting mode
		is_targeting = true
		targeting_card = card
		targeting_card_index = card_index
		targeting_max_range = max_range
		
		# Show and update targeting area
		if targeting_area:
			_update_targeting_visual()
			targeting_area.show()
			
		# Show targeting UI hint
		Events.show_targeting_hint.emit(card.name, true)
		return true
	
	# For non-targeting cards, execute immediately
	# Pay the energy cost
	energy -= card.energy_cost
	_emit_energy_changed()
	
	# Get target position and direction
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Execute card effect
	card.execute(self, mouse_pos, direction)
	
	# Move card to discard pile and signal
	card_manager.discard_card(card_index)
	Events.card_played.emit(card.name, card_index)
	
	
	return true

func take_damage(amount):
	if is_dead or is_invulnerable:
		return
		
	# Apply shield if available
	var remaining_damage = amount
	if shield_amount > 0:
		if shield_amount >= amount:
			shield_amount -= amount
			remaining_damage = 0
		else:
			remaining_damage -= shield_amount
			shield_amount = 0
		_emit_shield_changed()
	
	# Apply remaining damage to health
	if remaining_damage > 0:
		health -= remaining_damage
		_emit_health_changed()
		
		# Flash the character and make temporarily invulnerable
		is_invulnerable = true
		invulnerability_timer = 0.0
		
		# Play hit animation
		_play_animation("hit")
		
		if health <= 0:
			_die()
	else:
		# Visual feedback for blocked damage
		_play_animation("block")

func heal(amount):
	health = min(health + amount, max_health)
	_emit_health_changed()

func _die():
	is_dead = true
	_play_animation("death")
	Events.player_died.emit()
	# Disable collisions
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

func _on_hurt_box_area_entered(area):
	if area.is_in_group("enemy_attack"):
		take_damage(area.damage)

# Add shield to the player
func add_shield(amount: int, duration: float = 0.0):
	shield_amount += amount
	_emit_shield_changed()
	
	# If duration is specified, create a timer to remove the shield
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.connect("timeout", Callable(self, "_on_shield_expired").bind(amount))

func _on_shield_expired(amount: int):
	shield_amount = max(0, shield_amount - amount)
	_emit_shield_changed()

# Apply buff to the player (speed, damage, etc.)
func apply_buff(stat_name: String, value: float, duration: float):
	# Implementation depends on which stats can be buffed
	match stat_name:
		"speed":
			var original_speed = speed
			speed *= value
			
			# Create timer to revert the buff
			var timer = get_tree().create_timer(duration)
			timer.connect("timeout", Callable(self, "_on_speed_buff_expired").bind(original_speed))
		# Add other stats as needed

func _on_speed_buff_expired(original_speed: float):
	speed = original_speed

func _emit_health_changed():
	Events.player_health_changed.emit(health, max_health)

func _emit_shield_changed():
	Events.player_shield_changed.emit(shield_amount)

func _emit_energy_changed():
	Events.player_energy_changed.emit(energy, max_energy)

func _on_card_clicked(hand_index: int):
	play_card(hand_index)

func _setup_targeting_system():
	# Create targeting area if it doesn't exist
	if !has_node("TargetingArea"):
		var area = Area2D.new()
		area.name = "TargetingArea"
		
		# Add collision shape
		var collision = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		collision.shape = circle
		area.add_child(collision)
		collision.name = "CollisionShape2D"
		
		# Add visual circle
		var target_sprite = Sprite2D.new()
		target_sprite.name = "TargetingSprite"
		target_sprite.texture = load("res://Assets/icon.svg")  # Using default circle for now
		target_sprite.modulate = Color(1, 0, 0, 0.3)  # Semi-transparent red
		area.add_child(target_sprite)
		
		add_child(area)
		targeting_area = area
		targeting_area.hide()

func _update_targeting_visual():
	if targeting_area and is_targeting:
		var collision_shape = targeting_area.get_node("CollisionShape2D")
		var target_sprite = targeting_area.get_node("TargetingSprite")
		if collision_shape and target_sprite:
			var circle_shape = collision_shape.shape as CircleShape2D
			if circle_shape:
				circle_shape.radius = targeting_radius
				target_sprite.scale = Vector2(targeting_radius / 64.0, targeting_radius / 64.0)  # Assuming icon.svg is 64x64

func _unhandled_input(event):
	if is_targeting:
		if event is InputEventMouseMotion:
			# Get mouse position and clamp to max range
			var mouse_pos = get_global_mouse_position()
			var to_mouse = mouse_pos - global_position
			if to_mouse.length() > targeting_max_range:
				to_mouse = to_mouse.normalized() * targeting_max_range
				mouse_pos = global_position + to_mouse
			
			# Update targeting area position and visual
			targeting_area.global_position = mouse_pos
			_update_targeting_visual()
			
			# Update targeting area color based on range
			var is_in_range = to_mouse.length() <= targeting_max_range
			targeting_area.modulate = Color(1, 1, 1, 1) if is_in_range else Color(1, 0, 0, 0.5)
			
		elif event.is_action_pressed("ui_cancel") or event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_targeting()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var to_mouse = get_global_mouse_position() - global_position
			if to_mouse.length() <= targeting_max_range:
				_confirm_targeting()

func _cancel_targeting():
	is_targeting = false
	targeting_area.hide()
	targeting_card_index = -1
	targeting_card = null
	Events.targeting_cancelled.emit()
	# Energy wasn't spent, don't draw a new card

func _confirm_targeting():
	if is_targeting and targeting_card:
		var target_pos = get_global_mouse_position()
		var direction = (target_pos - global_position).normalized()
		
		# Pay energy cost first
		energy -= targeting_card.energy_cost
		_emit_energy_changed()
		
		# Execute the card and handle cleanup
		targeting_card.execute(self, target_pos, direction)
		card_manager.discard_card(targeting_card_index)
		Events.card_played.emit(targeting_card.name, targeting_card_index)
		Events.show_targeting_hint.emit(targeting_card.name, false)
		
		# Draw a new card if cooldown allows
		if can_draw:
			for i in range(cards_per_draw):
				var drawn = card_manager.draw_card()
				if not drawn:
					break
			can_draw = false
			draw_timer = 0.0
		
		# Reset targeting state
		is_targeting = false
		targeting_area.hide()
		targeting_card = null
		targeting_card_index = -1

func reset_for_room():
	# Reset energy to max
	energy = max_energy
	Events.emit_signal("player_energy_changed", energy, max_energy)
	
	# Clear any temporary buffs or status effects
	shield = 0
	Events.emit_signal("player_shield_changed", shield)
	
	# Reset position to starting point
	position = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y * 0.75)
