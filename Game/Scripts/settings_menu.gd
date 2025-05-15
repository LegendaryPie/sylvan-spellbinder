extends Window

signal closed

const SETTINGS_FILE = "user://settings.cfg"

@onready var master_volume = $MarginContainer/VBoxContainer/AudioSettings/MasterVolume
@onready var music_volume = $MarginContainer/VBoxContainer/AudioSettings/MusicVolume
@onready var sfx_volume = $MarginContainer/VBoxContainer/AudioSettings/SFXVolume
@onready var screen_shake = $MarginContainer/VBoxContainer/GameSettings/ScreenShake
@onready var show_damage_numbers = $MarginContainer/VBoxContainer/GameSettings/ShowDamageNumbers
@onready var apply_button = $MarginContainer/VBoxContainer/Buttons/ApplyButton
@onready var main_menu_button = $MarginContainer/VBoxContainer/Buttons/MainMenuButton
@onready var close_button = $MarginContainer/VBoxContainer/Buttons/CloseButton

var config = ConfigFile.new()

func _ready():
	apply_button.pressed.connect(_on_apply_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	close_button.pressed.connect(_on_close_pressed)
	close_requested.connect(_on_close_pressed)
	
	# Load saved settings
	load_settings()

func load_settings():
	var err = config.load(SETTINGS_FILE)
	if err != OK:
		return
	
	master_volume.value = config.get_value("audio", "master_volume", 1.0)
	music_volume.value = config.get_value("audio", "music_volume", 0.8)
	sfx_volume.value = config.get_value("audio", "sfx_volume", 1.0)
	screen_shake.button_pressed = config.get_value("game", "screen_shake", true)
	show_damage_numbers.button_pressed = config.get_value("game", "show_damage_numbers", true)
	
	apply_settings()

func save_settings():
	config.set_value("audio", "master_volume", master_volume.value)
	config.set_value("audio", "music_volume", music_volume.value)
	config.set_value("audio", "sfx_volume", sfx_volume.value)
	config.set_value("game", "screen_shake", screen_shake.button_pressed)
	config.set_value("game", "show_damage_numbers", show_damage_numbers.button_pressed)
	
	config.save(SETTINGS_FILE)

func apply_settings():
	# Audio settings
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 
		linear_to_db(master_volume.value))
		# Game settings will be stored in config and accessed when needed
	save_settings()

func _on_apply_pressed():
	save_settings()
	apply_settings()

func _on_main_menu_pressed():
	# Save settings before leaving
	save_settings()
	# Get the game scene node
	var game = get_parent()
	if game:
		game.return_to_main_menu()
	queue_free()

func _on_close_pressed():
	save_settings()
	emit_signal("closed")
	queue_free()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		queue_free()
