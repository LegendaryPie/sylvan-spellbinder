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
	card_database = get_node("/root/CardDatabase")

func setup_room_completion(room_type: String, rewards: Array, artifacts: Array = []):
	title_label.text = "%s Room Complete!" % room_type
	
	for reward in rewards:
		var reward_label = Label.new()
		reward_label.text = reward
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards_list.add_child(reward_label)
	
	# Set up card rewards based on room type
	var card_choices = _get_card_choices(room_type)
	if card_choices.size() > 0:
		card_rewards_panel.show()
		for card in card_choices:
			var card_button = _create_card_button(card)
			cards_grid.add_child(card_button)
	else:
		card_rewards_panel.hide()
	
	if artifacts.size() > 0:
		$MarginContainer/VBoxContainer/ArtifactsPanel.show()
		for artifact in artifacts:
			var artifact_button = _create_artifact_button(artifact)
			artifacts_grid.add_child(artifact_button)

func setup_floor_completion(floor_num: int):
	title_label.text = "Floor %d Complete!" % floor_num
	continue_button.text = "Enter Next Floor"
	
	# Add some celebratory text
	var congrats_label = Label.new()
	congrats_label.text = "Congratulations!\nYou've conquered this floor!"
	congrats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_list.add_child(congrats_label)

func _get_card_choices(room_type: String) -> Array:
	# Different room types offer different rarity probabilities
	var possible_cards = []
	match room_type:
		"Normal":
			# 70% Common, 25% Uncommon, 5% Rare
			for i in range(3):  # Show 3 card choices
				var roll = randf()
				if roll < 0.7:
					possible_cards.append(_get_random_card_of_rarity(CardResource.Rarity.COMMON))
				elif roll < 0.95:
					possible_cards.append(_get_random_card_of_rarity(CardResource.Rarity.UNCOMMON))
				else:
					possible_cards.append(_get_random_card_of_rarity(CardResource.Rarity.RARE))
		"Elite":
			# 40% Uncommon, 50% Rare, 10% Legendary
			for i in range(3):
				var roll = randf()
				if roll < 0.4:
					possible_cards.append(_get_random_card_of_rarity(CardResource.Rarity.UNCOMMON))
				elif roll < 0.9:
					possible_cards.append(_get_random_card_of_rarity(CardResource.Rarity.RARE))
				else:
					possible_cards.append(_get_random_card_of_rarity(CardResource.Rarity.LEGENDARY))
		"Boss":
			# 60% Rare, 40% Legendary
			for i in range(3):
				var roll = randf()
				if roll < 0.6:
					possible_cards.append(_get_random_card_of_rarity(CardResource.Rarity.RARE))
				else:
					possible_cards.append(_get_random_card_of_rarity(CardResource.Rarity.LEGENDARY))
	
	return possible_cards

func _get_random_card_of_rarity(rarity: CardResource.Rarity) -> CardResource:
	return card_database.get_random_card_by_rarity(rarity)

func _create_card_button(card: CardResource) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(120, 180)
	button.text = "[center]%s\n\n%s\n\nEnergy: %d[/center]" % [card.name, card.description, card.energy_cost]
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func(): _on_card_button_pressed(card))
	
	# Set color based on rarity
	match card.rarity:
		CardResource.Rarity.COMMON:
			button.modulate = Color.WHITE
		CardResource.Rarity.UNCOMMON:
			button.modulate = Color(0.3, 1, 1) # Cyan
		CardResource.Rarity.RARE:
			button.modulate = Color(1, 0.6, 0.1) # Orange
		CardResource.Rarity.LEGENDARY:
			button.modulate = Color(1, 0.4, 1) # Purple
	
	return button

func _create_artifact_button(artifact):
	var button = Button.new()
	button.custom_minimum_size = Vector2(120, 180)
	button.text = "%s\n\n%s" % [artifact.name, artifact.description]
	button.pressed.connect(func(): _on_artifact_button_pressed(artifact))
	return button

func _on_card_button_pressed(card: CardResource):
	emit_signal("card_selected", card)
	# Disable all card buttons after selection
	for child in cards_grid.get_children():
		child.disabled = true
	
	# If no artifacts to choose, enable continue
	if not $MarginContainer/VBoxContainer/ArtifactsPanel.visible:
		continue_button.disabled = false

func _on_artifact_button_pressed(artifact):
	emit_signal("artifact_selected", artifact)
	# Disable all artifact buttons after selection
	for child in artifacts_grid.get_children():
		child.disabled = true
	continue_button.disabled = false

func _on_continue_button_pressed():
	emit_signal("continue_pressed")
	queue_free()
