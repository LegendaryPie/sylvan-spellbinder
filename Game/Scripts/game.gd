extends Node2D

# Game state
var current_score: int = 0
var current_level: int = 1
var current_floor: int = 1
var current_room: RoomResource
var is_paused: bool = false
var in_room: bool = false

# Save system
const SAVE_FILE = "user://game_save.dat"
const AUTOSAVE_INTERVAL = 300.0  # Save every 5 minutes
var time_since_last_save: float = 0.0

# Menu system
@onready var settings_menu_scene = load("res://Game/Scenes/settings_menu.tscn")
var is_menu_open: bool = false

# Scene references
@onready var dungeon_map_scene = preload("res://Game/Scenes/dungeon_map.tscn")
var active_map: Node

# Node references
@onready var player = $Player
@onready var card_database = $Player/CardDatabase
@onready var card_deck_manager = $Player/CardDeckManager
@onready var enemy_manager = $EnemyManager
@onready var enemy_database = $EnemyManager/EnemyDatabase
@onready var game_ui = $GameUI
@onready var score_label = $TopRightUI/TopRight/ScoreLabel
@onready var level_label = $TopRightUI/TopRight/LevelLabel
@onready var spawn_points_container = $SpawnPoints

# Enemy spawn points
@export var spawn_points: Array[Node] = []

func _ready():
	# Initialize game systems
	if not _try_load_game():
		_initialize_game()
	_setup_signals()
	_update_ui()

func _physics_process(delta):
	# Handle autosave
	if not is_paused:
		time_since_last_save += delta
		if time_since_last_save >= AUTOSAVE_INTERVAL:
			save_game()
			time_since_last_save = 0.0

func _initialize_game():
	# Make sure the card database is ready
	if card_database:
		card_database._load_all_cards()
	
	# Initialize enemy system
	if enemy_manager:
		enemy_manager.spawn_points = spawn_points_container.get_children()
		enemy_manager.enemy_died.connect(_on_enemy_died)
	
	# Connect UI signals
	if game_ui:
		game_ui.return_to_map_requested.connect(_on_return_to_map_requested)
	
	# Start with default game settings
	current_score = 0
	current_level = 1
	current_floor = 1
	is_paused = false
	in_room = false
	_update_ui()
	
	# Show the dungeon map
	show_dungeon_map()

func show_dungeon_map():
	in_room = false
	
	# Hide game UI elements
	if game_ui:
		game_ui.hide()
	
	# Remove existing map if any
	if active_map:
		active_map.queue_free()
	
	# Create and show new map
	active_map = dungeon_map_scene.instantiate()
	add_child(active_map)
	active_map.room_selected.connect(_on_room_selected)

func _on_room_selected(room: RoomResource):
	current_room = room
	enter_room(room)

func enter_room(room: RoomResource):
	current_room = room
	in_room = true
	
	# Show game UI and hide map
	toggle_game_view(true)
	
	match room.type:
		RoomResource.RoomType.BATTLE, RoomResource.RoomType.ELITE, RoomResource.RoomType.BOSS:
			if room is BattleRoomResource:
				_setup_battle(room)
		RoomResource.RoomType.REST:
			_apply_rest_bonus(room)
		RoomResource.RoomType.TREASURE:
			_give_treasure(room)
	
	# Reset player state for new room
	if player:
		player.reset_for_room()

func _setup_battle(battle_room: BattleRoomResource):
	# Clear any existing enemies
	enemy_manager.clear_enemies()
	
	# Spawn enemies based on room configuration
	for enemy_type in battle_room.enemy_types:
		var enemy_data = enemy_database.get_enemy(enemy_type)
		if enemy_data:
			enemy_manager.spawn_enemy(enemy_data, _get_random_spawn_point())

func _apply_rest_bonus(room: RoomResource):
	if room.health_bonus > 0:
		player.heal(room.health_bonus)
	_complete_room()

func _give_treasure(room: RoomResource):
	if room.gold_reward > 0:
		current_score += room.gold_reward
	if room.artifact_reward:
		# TODO: Implement artifact system
		pass
	_complete_room()

func _complete_room():
	if current_room:
		current_room.complete_room()
		Events.emit_signal("room_completed", current_room)
		
		# Apply rewards
		if current_room.gold_reward > 0:
			current_score += current_room.gold_reward
			Events.emit_signal("reward_earned", "gold", current_room.gold_reward)
		
		if current_room.health_bonus > 0:
			Events.emit_signal("reward_earned", "health", current_room.health_bonus)
		
		if current_room.card_reward:
			Events.emit_signal("reward_earned", "card", 1)
			# TODO: Show card reward selection UI
			pass
		
		if current_room.artifact_reward:
			Events.emit_signal("reward_earned", "artifact", 1)
		
		# Check if floor is completed (boss defeated)
		if current_room.type == RoomResource.RoomType.BOSS:
			current_floor += 1
			# Show floor completion UI and generate new floor
			_on_floor_completed()
		
		current_room = null
		in_room = false
		Events.emit_signal("return_to_map_requested")

func _get_random_spawn_point() -> Vector2:
	if spawn_points.size() > 0:
		var point = spawn_points[randi() % spawn_points.size()]
		return point.global_position
	return Vector2.ZERO

func _setup_signals():
	# Connect to Events singleton
	Events.player_died.connect(_on_player_died)
	Events.card_played.connect(_on_card_played)
	Events.enemy_died.connect(_on_enemy_died)
	
	if enemy_manager:
		enemy_manager.enemy_spawned.connect(_on_enemy_spawned)

func save_game():
	var save_data = {
		"game_state": {
			"score": current_score,
			"level": current_level,
				"floor": current_floor,
			"timestamp": Time.get_unix_time_from_system()
		},
		"player_state": {
			"health": player.health,
			"max_health": player.max_health,
			"energy": player.energy,
			"max_energy": player.max_energy,
			"position": {
				"x": player.position.x,
				"y": player.position.y
			}
		},
		"card_state": {
			"deck": _serialize_card_array(card_deck_manager.deck),
			"hand": _serialize_card_array(card_deck_manager.hand),
			"discard": _serialize_card_array(card_deck_manager.discard_pile)
		},
		"enemy_state": {
			"active_enemies": _serialize_enemies()
		}
	}
	
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		print("Game saved successfully")
	else:
		push_error("Failed to save game")

func _serialize_enemies() -> Array:
	var enemy_data = []
	if enemy_manager:
		for enemy in enemy_manager.active_enemies:
			enemy_data.append({
				"type": enemy.resource.id,
				"health": enemy.health,
				"position": {
					"x": enemy.position.x,
					"y": enemy.position.y
				}
			})
	return enemy_data

func _try_load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE):
		return false
	
	var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not save_file:
		return false
	
	var save_data = save_file.get_var()
	if not save_data:
		return false
	
	# Load game state
	if save_data.has("game_state"):
		current_score = save_data.game_state.score
		current_level = save_data.game_state.level
	
	# Load player state
	if save_data.has("player_state"):
		var p_state = save_data.player_state
		player.health = p_state.health
		player.max_health = p_state.max_health
		player.energy = p_state.energy
		player.max_energy = p_state.max_energy
		player.position = Vector2(p_state.position.x, p_state.position.y)
	
	# Load card state
	if save_data.has("card_state") and card_database and card_deck_manager:
		# Make sure card database is initialized first
		card_database._load_all_cards()
		
		# Restore card states
		card_deck_manager.set_deck(_deserialize_card_array(save_data.card_state.deck))
		card_deck_manager.set_hand(_deserialize_card_array(save_data.card_state.hand))
		card_deck_manager.set_discard_pile(_deserialize_card_array(save_data.card_state.discard))
	
	# Load enemy state
	if save_data.has("enemy_state") and enemy_manager and enemy_database:
		for enemy_data in save_data.enemy_state.active_enemies:
			var enemy_resource = enemy_database.get_enemy(enemy_data.type)
			if enemy_resource:
				var enemy_instance = enemy_manager.enemy_scene.instantiate()
				enemy_instance.resource = enemy_resource
				enemy_instance.position = Vector2(enemy_data.position.x, enemy_data.position.y)
				enemy_instance.health = enemy_data.health
				enemy_manager.add_child(enemy_instance)
				enemy_manager.active_enemies.append(enemy_instance)
	
	print("Game loaded successfully")
	return true

func _serialize_card_array(cards: Array) -> Array:
	var serialized = []
	for card in cards:
		if card is CardResource:
			serialized.append(card.id)
	return serialized

func _deserialize_card_array(card_ids: Array) -> Array:
	var deserialized = []
	for card_id in card_ids:
		var card = card_database.get_card(card_id)
		if card:
			deserialized.append(card.create_instance())
	return deserialized

func _on_player_died():
	# Handle player death
	print("Game Over - Score: ", current_score)
	
	# Show game over screen
	var game_over_scene = load("res://Game/Scenes/game_over.tscn")
	var game_over = game_over_scene.instantiate()
	add_child(game_over)
	game_over.set_score(current_score)
	
	# Pause the game
	get_tree().paused = true

func _on_card_played(card_name: String):
	# Handle any game-wide effects when cards are played
	print("Card played: ", card_name)
	# You might want to update UI, trigger events, etc.

func _check_level_progression():
	# Example: Progress to next level after certain score thresholds
	var level_threshold = current_level * 1000  # Adjust this formula as needed
	if current_score >= level_threshold:
		current_level += 1
		_update_ui()
		_on_level_up()

func _on_level_up():
	# Increase difficulty
	if enemy_manager:
		enemy_manager.max_enemies += 2
		enemy_manager.spawn_interval = max(1.0, enemy_manager.spawn_interval * 0.9)
	
	# Here you could also:
	# - Give player rewards
	# - Spawn boss
	# - Change environment
	# - etc.

func _on_enemy_spawned(_enemy: Enemy):
	# Handle any game-wide effects when an enemy spawns
	pass

func _input(event):
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	
	if is_paused and not is_menu_open:
		var settings = settings_menu_scene.instantiate()
		settings.closed.connect(_on_settings_menu_closed)
		add_child(settings)
		settings.popup_centered()
		is_menu_open = true
	elif not is_paused and is_menu_open:
		var settings = get_node_or_null("SettingsMenu")
		if settings:
			settings.queue_free()
		is_menu_open = false

func return_to_main_menu():
	# Save game before leaving
	save_game()
	# Change back to main menu scene
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Game/Scenes/main_menu.tscn")

# Add a signal connection for the settings menu
func _on_settings_menu_closed():
	is_menu_open = false
	if is_paused:
		_toggle_pause()

func _update_ui():
	if score_label:
		score_label.text = "Score: %d" % current_score
	if level_label:
		level_label.text = "Level: %d" % current_level

func toggle_game_view(show_game: bool):
	# Toggle game UI elements
	if game_ui:
		game_ui.visible = show_game
	
	# Toggle map
	if active_map:
		active_map.visible = !show_game
	
	# Toggle enemy manager visibility
	if enemy_manager:
		enemy_manager.visible = show_game
	
	# Toggle player visibility
	if player:
		player.visible = show_game

func _on_return_to_map_requested():
	if in_room and not is_paused:
		show_dungeon_map()
		toggle_game_view(false)

func _on_enemy_died(enemy):
	# Update score
	if enemy.resource:
		current_score += enemy.resource.score_value
		_update_ui()
	
	# Check if room completion conditions are met
	if current_room and (current_room.type == RoomResource.RoomType.BATTLE or 
		current_room.type == RoomResource.RoomType.ELITE or
		current_room.type == RoomResource.RoomType.BOSS):
		if enemy_manager and enemy_manager.get_enemy_count() == 0:
			_complete_room()

func _on_floor_completed():
	# Save progress
	save_game()
	
	# Emit floor completed signal before generating new floor
	Events.emit_signal("floor_completed", current_floor)
	
	# Generate new floor
	if active_map:
		active_map.current_floor = current_floor
		active_map.generate_map()
