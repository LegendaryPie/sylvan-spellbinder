extends CanvasLayer

@export var card_scene: PackedScene



# UI node references
@onready var health_bar = $TopBar/MarginContainer/HBoxContainer/HealthBar
@onready var health_label = $TopBar/MarginContainer/HBoxContainer/HealthBar/HealthLabel
@onready var shield_bar = $TopBar/MarginContainer/HBoxContainer/HealthBar/ShieldBar
@onready var shield_label = $TopBar/MarginContainer/HBoxContainer/HealthBar/ShieldLabel
@onready var energy_bar = $TopBar/MarginContainer/HBoxContainer/EnergyBar
@onready var energy_label = $TopBar/MarginContainer/HBoxContainer/EnergyBar/EnergyLabel
@onready var hand_container = $HandContainer
@onready var deck_count = $DeckInfo/DeckCount
@onready var discard_count = $DiscardInfo/DiscardCount
@onready var deck_button = $DeckInfo
@onready var discard_button = $DiscardInfo
@onready var cards_popup = $CardsPopup
@onready var cards_list = $CardsPopup/VBoxContainer/CardsList
@onready var popup_title = $CardsPopup/VBoxContainer/Title
@onready var popup_close = $CardsPopup/VBoxContainer/CloseButton
@onready var targeting_hint = $TargetingHint
@onready var map_button = $MapButton

var card_nodes: Array[Node] = []
var is_targeting: bool = false
var normal_modulate: Color = Color(1, 1, 1, 1)
var disabled_modulate: Color = Color(0.7, 0.7, 0.7, 0.5)

# Track artifact display
var artifact_nodes: Array = []

func _ready():
	# Connect to Events singleton signals
	Events.player_health_changed.connect(_on_player_health_changed)
	Events.player_energy_changed.connect(_on_player_energy_changed)
	Events.player_shield_changed.connect(_on_player_shield_changed)
	Events.card_drawn.connect(_on_card_drawn)
	Events.card_played.connect(_on_card_played)
	Events.show_targeting_hint.connect(_on_show_targeting_hint)
	Events.targeting_cancelled.connect(_on_targeting_cancelled)
	Events.reward_earned.connect(_on_reward_earned)
	
	# Setup shield bar
	if shield_bar:
		shield_bar.max_value = 100  # Will be relative to max health
		shield_bar.value = 0
		shield_bar.show_percentage = false
		shield_bar.modulate = Color(0, 0.7, 1, 0.8)  # Light blue, slightly transparent
	
	if shield_label:
		shield_label.text = "0"
		shield_label.visible = false
	
	# Connect deck/discard button signals
	deck_button.gui_input.connect(_on_deck_button_input)
	discard_button.gui_input.connect(_on_discard_button_input)
	
	# Connect popup close button
	var close_button = $CardsPopup/VBoxContainer/CloseButton
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Initialize targeting hint
	if !targeting_hint:
		targeting_hint = Label.new()
		targeting_hint.name = "TargetingHint"
		targeting_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		targeting_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		targeting_hint.anchor_right = 1.0
		targeting_hint.anchor_bottom = 0.0
		targeting_hint.offset_bottom = 40
		add_child(targeting_hint)
		targeting_hint.hide()
	
	# Connect map button
	if map_button:
		map_button.pressed.connect(_on_map_button_pressed)

	if get_tree().get_root().has_node("Game/Player/ArtifactManager"):
		var artifact_manager = get_tree().get_root().get_node("Game/Player/ArtifactManager")
		artifact_manager.artifact_added.connect(_on_artifact_added)
		artifact_manager.artifact_removed.connect(_on_artifact_removed)

func _set_ui_interactable(interactable: bool):
	deck_button.mouse_filter = Control.MOUSE_FILTER_STOP if interactable else Control.MOUSE_FILTER_IGNORE
	discard_button.mouse_filter = Control.MOUSE_FILTER_STOP if interactable else Control.MOUSE_FILTER_IGNORE
	
	# Visual feedback
	deck_button.modulate = normal_modulate if interactable else disabled_modulate
	discard_button.modulate = normal_modulate if interactable else disabled_modulate
	
	# If targeting is starting, close any open popups
	if not interactable:
		cards_popup.hide()

func _on_player_health_changed(current: int, maximum: int):
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d/%d" % [current, maximum]

func _on_player_energy_changed(current: float, maximum: float):
	energy_bar.max_value = maximum
	energy_bar.value = current
	energy_label.text = "%d/%d" % [int(current), int(maximum)]

func _on_player_shield_changed(shield_value: int):
	if shield_bar:
		shield_bar.max_value = health_bar.max_value  # Scale relative to max health
		shield_bar.value = shield_value
		shield_bar.visible = shield_value > 0
		
	if shield_label:
		shield_label.text = str(shield_value)
		shield_label.visible = shield_value > 0

func _on_card_drawn(card: CardResource, hand_index: int):
	if card_scene and card:
		var card_instance = card_scene.instantiate()
		hand_container.add_child(card_instance)
		card_nodes.append(card_instance)
		card_instance.set_card(card, hand_index)
		_update_card_counts()

func _on_card_played(_card_name: String, hand_index: int):
	# Remove the played card from UI
	if hand_index >= 0 and hand_index < card_nodes.size():
		# Remove and free the card UI node
		var card_node = card_nodes[hand_index]
		hand_container.remove_child(card_node)
		card_node.queue_free()
		card_nodes.remove_at(hand_index)
		
		# Update indices for remaining cards
		for i in range(hand_index, card_nodes.size()):
			card_nodes[i].hand_index = i
	
	# Update deck and discard counts
	_update_card_counts()

func _update_card_counts():
	var card_manager = get_parent().get_node("Player/CardDeckManager")
	if card_manager:
		deck_count.text = str(card_manager.deck.size())
		discard_count.text = str(card_manager.discard_pile.size())

func _on_deck_button_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_targeting:
			_show_deck_contents()

func _on_discard_button_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_targeting:
			_show_discard_contents()

var current_cards: Array[CardResource] = []

func _show_deck_contents():
	var card_manager = get_parent().get_node("Player/CardDeckManager")
	if card_manager:
		popup_title.text = "Cards in Deck"
		current_cards = card_manager.get_sorted_deck_contents()
		_show_cards_list(current_cards)

func _show_discard_contents():
	var card_manager = get_parent().get_node("Player/CardDeckManager")
	if card_manager:
		popup_title.text = "Cards in Discard Pile"
		current_cards = card_manager.get_discard_contents()
		_show_cards_list(current_cards)

func _show_cards_list(cards: Array[CardResource]):
	cards_list.clear()
	current_cards = cards
	
	for card in cards:
		var display_text = card.name
		var type_text = CardResource.CardType.keys()[card.type]
		var rarity_text = CardResource.Rarity.keys()[card.rarity]
		
		var tooltip = "%s\nType: %s\nRarity: %s\nEnergy: %d\n%s" % [
			card.name,
			type_text,
			rarity_text,
			card.energy_cost,
			card.get_formatted_description()
		]
		
		cards_list.add_item(display_text, null, true)  # Make item selectable
		var idx = cards_list.item_count - 1
		
		# Color the item based on rarity
		match card.rarity:
			CardResource.Rarity.COMMON:
				cards_list.set_item_custom_fg_color(idx, Color.WHITE)
			CardResource.Rarity.UNCOMMON:
				cards_list.set_item_custom_fg_color(idx, Color(0.3, 1, 1)) # Cyan
			CardResource.Rarity.RARE:
				cards_list.set_item_custom_fg_color(idx, Color(1, 0.6, 0.1)) # Orange
			CardResource.Rarity.LEGENDARY:
				cards_list.set_item_custom_fg_color(idx, Color(1, 0.4, 1)) # Purple
				
		cards_list.set_item_tooltip(idx, tooltip)
		cards_list.set_item_tooltip_enabled(idx, true)
	
	cards_popup.popup_centered()

func _on_close_button_pressed():
	cards_popup.hide()

func _on_show_targeting_hint(spell_name: String, should_show: bool):
	if targeting_hint:
		targeting_hint.text = "Select target for %s (ESC or right-click to cancel)" % spell_name
		if should_show:
			targeting_hint.show()
			is_targeting = true
			_set_ui_interactable(false)
		else:
			targeting_hint.hide()
			is_targeting = false
			_set_ui_interactable(true)
		
func _on_targeting_cancelled():
	if targeting_hint:
		targeting_hint.hide()
		is_targeting = false
		_set_ui_interactable(true)

func _on_map_button_pressed():
	Events.return_to_map_requested.emit()

# UI scene references
@onready var floating_text_scene = preload("res://Game/Scenes/floating_text.tscn")
@onready var completion_panel_scene = preload("res://Game/Scenes/completion_panel.tscn")

var active_completion_panel: Node

func _on_reward_earned(reward_type: String, amount: int):
	var reward_text = ""
	var text_color = Color.WHITE
	
	match reward_type:
		"gold":
			reward_text = "+%d Gold!" % amount
			text_color = Color(1, 0.85, 0.4)  # Gold color
		"health":
			reward_text = "+%d HP!" % amount
			text_color = Color(0.2, 0.9, 0.3)  # Green color
		"card":
			reward_text = "New Card!"
			text_color = Color(0.4, 0.7, 1)  # Light blue
		"artifact":
			reward_text = "Artifact Found!"
			text_color = Color(0.8, 0.4, 1)  # Purple
	
	spawn_floating_text(reward_text, text_color)

func spawn_floating_text(text: String, color: Color = Color.WHITE):
	var floating_text = floating_text_scene.instantiate()
	add_child(floating_text)
	
	# Position near the center-top of the screen
	floating_text.position = Vector2(
		randf_range(400, get_viewport().size.x - 400),
		get_viewport().size.y * 0.4
	)
	floating_text.display(text, color)

func _on_completion_continue():
	active_completion_panel = null
	Events.return_to_map_requested.emit()
	# The panel will clean itself up

func _on_artifact_added(artifact: ArtifactResource):
	_add_artifact_display(artifact)
	
func _on_artifact_removed(artifact: ArtifactResource):
	# Find and remove the artifact's display
	for node in artifact_nodes:
		if node.artifact_id == artifact.id:
			node.queue_free()
			artifact_nodes.erase(node)
			break

func _add_artifact_display(artifact: ArtifactResource):
	var artifact_icon = TextureRect.new()
	artifact_icon.texture = load(artifact.texture_path) if artifact.texture_path else load("res://Assets/icon.svg")
	artifact_icon.custom_minimum_size = Vector2(32, 32)
	artifact_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	artifact_icon.tooltip_text = "%s\n%s" % [artifact.name, artifact.description]
	artifact_icon.set_meta("artifact_id", artifact.id)
	
	# Add to artifacts container
	if has_node("ArtifactsContainer"):
		$ArtifactsContainer.add_child(artifact_icon)
		artifact_nodes.append(artifact_icon)
