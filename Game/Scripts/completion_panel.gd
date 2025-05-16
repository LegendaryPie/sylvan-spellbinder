extends PanelContainer

signal continue_pressed

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var rewards_list = $MarginContainer/VBoxContainer/RewardsPanel/MarginContainer/RewardsList
@onready var continue_button = $MarginContainer/VBoxContainer/ContinueButton

func _ready():
	continue_button.pressed.connect(_on_continue_button_pressed)
	# Start with a scale effect
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func setup_room_completion(room_type: String, rewards: Array):
	title_label.text = "%s Room Complete!" % room_type
	
	for reward in rewards:
		var reward_label = Label.new()
		reward_label.text = reward
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards_list.add_child(reward_label)

func setup_floor_completion(floor_num: int):
	title_label.text = "Floor %d Complete!" % floor_num
	continue_button.text = "Enter Next Floor"
	
	# Add some celebratory text
	var congrats_label = Label.new()
	congrats_label.text = "Congratulations!\nYou've conquered this floor!"
	congrats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_list.add_child(congrats_label)

func _on_continue_button_pressed():
	# Add a quick fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
	tween.tween_callback(func(): 
		continue_pressed.emit()
		queue_free()
	)
