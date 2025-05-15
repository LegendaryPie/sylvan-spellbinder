extends Node2D

# Game state
var current_score: int = 0
var current_level: int = 1
var is_paused: bool = false

# Save system
const SAVE_FILE = "user://game_save.dat"
const AUTOSAVE_INTERVAL = 300.0  # Save every 5 minutes
var time_since_last_save: float = 0.0

# Menu system
@onready var settings_menu_scene = load("res://Game/Scenes/settings_menu.tscn")
var is_menu_open: bool = false

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
	
	# Start with default game settings
	current_score = 0
	current_level = 1
	is_paused = false
	_update_ui()

func _setup_signals():
	# Connect to Events singleton
	Events.player_died.connect(_on_player_died)
	Events.card_played.connect(_on_card_played)
	
	if enemy_manager:
		enemy_manager.enemy_spawned.connect(_on_enemy_spawned)

func save_game():
	var save_data = {
		"game_state": {
			"score": current_score,
			"level": current_level,
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
	# Handle player death (game over, restart, etc.)
	print("Game Over - Score: ", current_score)
	# Save the game state before showing game over screen
	save_game()
	# Here you would typically show a game over screen
	# or handle restart logic

func _on_card_played(card_name: String):
	# Handle any game-wide effects when cards are played
	print("Card played: ", card_name)
	# You might want to update UI, trigger events, etc.

func _on_enemy_died(enemy: Enemy):
	# Update score
	if enemy.resource:
		current_score += enemy.resource.score_value
		_update_ui()
	
	# Consider level progression or other game mechanics
	_check_level_progression()

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
