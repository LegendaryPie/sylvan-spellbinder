extends PanelContainer

signal continue_pressed
signal artifact_selected(artifact)
signal card_selected(card)

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var rewards_list = $MarginContainer/VBoxContainer/RewardsPanel/MarginContainer/RewardsList
@onready var cards_grid: HBoxContainer = $MarginContainer/VBoxContainer/CardRewardsPanel/MarginContainer/VBoxContainer/CardsGrid
@onready var artifacts_grid: HBoxContainer = $MarginContainer/VBoxContainer/ArtifactsPanel/MarginContainer/VBoxContainer/ArtifactsGrid
@onready var continue_button = $MarginContainer/VBoxContainer/ContinueButton
@onready var card_rewards_panel = $MarginContainer/VBoxContainer/CardRewardsPanel

var card_database: CardDatabase
var card_ui_scene = preload("res://Game/Scenes/card_ui.tscn")

func _ready():
	# Enable the button initially
	continue_button.disabled = false
	continue_button.pressed.connect(_on_continue_button_pressed)
	
	# Set up initial properties
	custom_minimum_size = Vector2(300, 200)
	size_flags_horizontal = SIZE_SHRINK_CENTER
	size_flags_vertical = SIZE_SHRINK_CENTER
	
	# Position in center of screen
	var viewport_size = get_viewport_rect().size
	position = (viewport_size - size) / 2
	
	# Ensure button is visible and clickable
	continue_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Start with a scale effect
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Get reference to card database
	card_database = get_node_or_null("/root/Game/Player/CardDatabase")
	if not card_database:
		push_error("Failed to find CardDatabase node")

func setup_room_completion(room_type: String, rewards: Array, artifacts: Array = []):
	title_label.text = "%s Room Complete!" % room_type
	
	# Add basic rewards
	for reward in rewards:
		var reward_label = Label.new()
		reward_label.text = reward
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards_list.add_child(reward_label)
	
	# Set up card rewards based on room type if database is available
	if card_database:
		var possible_cards = []
		# Different room types offer different rarity probabilities
		match room_type:
			"Battle":
				# 70% Common, 25% Uncommon, 5% Rare
				for i in range(3):
					var roll = randf()
					if roll < 0.7:
						possible_cards.append(card_database.get_random_card_by_rarity(CardResource.Rarity.COMMON))
					elif roll < 0.95:
						possible_cards.append(card_database.get_random_card_by_rarity(CardResource.Rarity.UNCOMMON))
					else:
						possible_cards.append(card_database.get_random_card_by_rarity(CardResource.Rarity.RARE))
			"Elite":
				# 40% Uncommon, 50% Rare, 10% Legendary
				for i in range(3):
					var roll = randf()
					if roll < 0.4:
						possible_cards.append(card_database.get_random_card_by_rarity(CardResource.Rarity.UNCOMMON))
					elif roll < 0.9:
						possible_cards.append(card_database.get_random_card_by_rarity(CardResource.Rarity.RARE))
					else:
						possible_cards.append(card_database.get_random_card_by_rarity(CardResource.Rarity.LEGENDARY))
			"Boss":
				# 60% Rare, 40% Legendary
				for i in range(3):
					var roll = randf()
					if roll < 0.6:
						possible_cards.append(card_database.get_random_card_by_rarity(CardResource.Rarity.RARE))
					else:
						possible_cards.append(card_database.get_random_card_by_rarity(CardResource.Rarity.LEGENDARY))
		
		if possible_cards.size() > 0:
			card_rewards_panel.show()
			for card in possible_cards:
				if card:  # Make sure we got a valid card
					var card_ui = card_ui_scene.instantiate()
					cards_grid.add_child(card_ui)
					card_ui.set_card(card, -1)  # -1 for hand index since this isn't in hand
					card_ui.gui_input.connect(func(event): _on_card_ui_input(event, card))
		else:
			card_rewards_panel.hide()
	else:
		card_rewards_panel.hide()
		push_error("No card database available for rewards")
	
	if artifacts.size() > 0:
		$MarginContainer/VBoxContainer/ArtifactsPanel.show()
		for artifact in artifacts:
			var artifact_display = _create_artifact_display(artifact)
			artifacts_grid.add_child(artifact_display)
	else:
		$MarginContainer/VBoxContainer/ArtifactsPanel.hide()

func _create_artifact_display(artifact: ArtifactResource) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(64, 80)
	
	var icon = TextureRect.new()
	icon.texture = load(artifact.texture_path) if artifact.texture_path else load("res://Assets/icon.svg")
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	icon.tooltip_text = "%s\n%s" % [artifact.name, artifact.description]
	icon.gui_input.connect(func(event): _on_artifact_input(event, artifact))
	container.add_child(icon)
	icon.position = Vector2(0, 0)
	
	return container

func _on_card_ui_input(event: InputEvent, card: CardResource):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("card_selected", card)
		# Disable all card UIs after selection
		for child in cards_grid.get_children():
			child.modulate = Color(0.5, 0.5, 0.5, 0.5)
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# If no artifacts to choose, enable continue button
		if not $MarginContainer/VBoxContainer/ArtifactsPanel.visible:
			continue_button.disabled = false

func _on_artifact_input(event: InputEvent, artifact):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("artifact_selected", artifact)
		# Disable all artifact icons after selection
		for child in artifacts_grid.get_children():
			child.modulate = Color(0.5, 0.5, 0.5, 0.5)
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		continue_button.disabled = false

func _on_continue_button_pressed():
	emit_signal("continue_pressed")
	queue_free()
