extends Control

const SAVE_FILE = "user://game_save.dat"

@onready var continue_button = $MainContainer/ContinueButton
@onready var new_game_button = $MainContainer/NewGameButton
@onready var settings_button = $MainContainer/SettingsButton
@onready var exit_button = $MainContainer/ExitButton

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Show/hide continue button based on save existence
	continue_button.visible = FileAccess.file_exists(SAVE_FILE)

func _on_continue_pressed():
	# Load game scene with existing save
	get_tree().change_scene_to_file("res://Game/Scenes/game.tscn")

func _on_new_game_pressed():
	# Delete existing save if it exists
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
	# Load fresh game scene
	get_tree().change_scene_to_file("res://Game/Scenes/game.tscn")

func _on_settings_pressed():
	# We'll implement this when we create the settings menu
	var settings_dialog = preload("res://Game/Scenes/settings_menu.tscn").instantiate()
	add_child(settings_dialog)
	settings_dialog.popup_centered()

func _on_exit_pressed():
	get_tree().quit()
