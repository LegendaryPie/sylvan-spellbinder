extends CanvasLayer

@export var card_scene: PackedScene

# UI node references
@onready var health_bar = $TopBar/MarginContainer/HBoxContainer/HealthBar
@onready var health_label = $TopBar/MarginContainer/HBoxContainer/HealthBar/HealthLabel
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

var card_nodes: Array[Node] = []

func _ready():
	# Connect to Events singleton signals
	Events.player_health_changed.connect(_on_player_health_changed)
	Events.player_energy_changed.connect(_on_player_energy_changed)
	Events.card_drawn.connect(_on_card_drawn)
	Events.card_played.connect(_on_card_played)
	Events.show_targeting_hint.connect(_on_show_targeting_hint)
	Events.targeting_cancelled.connect(_on_targeting_cancelled)
	
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

func _on_player_health_changed(current: int, maximum: int):
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d/%d" % [current, maximum]

func _on_player_energy_changed(current: float, maximum: float):
	energy_bar.max_value = maximum
	energy_bar.value = current
	energy_label.text = "%d/%d" % [int(current), int(maximum)]

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
		_show_deck_contents()

func _on_discard_button_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
		var tooltip = "%s\nType: %s\nEnergy: %d\n%s" % [
			card.name,
			card.type.capitalize(),
			card.energy_cost,
			card.get_formatted_description()
		]
		cards_list.add_item(display_text, null, true)  # Make item selectable
		var idx = cards_list.item_count - 1
		cards_list.set_item_tooltip(idx, tooltip)
		cards_list.set_item_tooltip_enabled(idx, true)
	
	cards_popup.popup_centered()

func _on_close_button_pressed():
	cards_popup.hide()

func _on_show_targeting_hint(spell_name: String):
	if targeting_hint:
		targeting_hint.text = "Select target for %s (ESC to cancel)" % spell_name
		targeting_hint.show()

func _on_targeting_cancelled():
	if targeting_hint:
		targeting_hint.hide()
