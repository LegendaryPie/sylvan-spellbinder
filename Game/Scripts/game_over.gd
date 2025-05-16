extends CanvasLayer

@onready var score_label = $Panel/VBoxContainer/ScoreLabel
@onready var restart_button = $Panel/VBoxContainer/RestartButton
@onready var main_menu_button = $Panel/VBoxContainer/MainMenuButton

func _ready():
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func set_score(score: int):
	score_label.text = "Score: %d" % score

func _on_restart_pressed():
	# Delete save file to start fresh
	if FileAccess.file_exists("user://game_save.dat"):
		DirAccess.remove_absolute("user://game_save.dat")
	# Reload current scene
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	# Delete save file
	if FileAccess.file_exists("user://game_save.dat"):
		DirAccess.remove_absolute("user://game_save.dat")
	# Return to main menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Game/Scenes/main_menu.tscn")
