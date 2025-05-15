# CardDeckManager.gd - Manages deck, hand and discard pile
extends Node
class_name CardDeckManager

@export var starting_deck_composition: Dictionary = {
	"quick_slash": 4,    # Basic attack card, main damage source
	"fireball": 2,       # Area damage with DoT
	"healing_light": 2,  # Health restoration
	"arcane_barrier": 2  # Defense card
}

@export var max_hand_size: int = 5
@export var starting_hand_size: int = 3
@export var cards_per_draw: int = 1

var deck: Array[CardResource] = []
var hand: Array[CardResource] = []
var discard_pile: Array[CardResource] = []

@onready var card_database: CardDatabase = $"../CardDatabase"

func _ready():
	# Delay initialization to next frame to ensure all nodes have connected to signals
	call_deferred("_delayed_init")

func _delayed_init():
	_initialize_deck()
	_draw_starting_hand()

func _initialize_deck():
	# Create deck from starting composition
	for card_id in starting_deck_composition:
		var count = starting_deck_composition[card_id]
		for i in range(count):
			var card = card_database.get_card(card_id)
			if card:
				deck.append(card.create_instance())
	
	# Shuffle the deck
	deck.shuffle()

func _draw_starting_hand():
	for i in range(min(starting_hand_size, deck.size())):
		draw_card()

func set_deck(new_deck: Array) -> void:
	deck.clear()
	for card in new_deck:
		if card is CardResource:
			deck.append(card)

func set_hand(new_hand: Array) -> void:
	hand.clear()
	for card in new_hand:
		if card is CardResource:
			hand.append(card)

func set_discard_pile(new_discard: Array) -> void:
	discard_pile.clear()
	for card in new_discard:
		if card is CardResource:
			discard_pile.append(card)

func draw_card() -> bool:
	if deck.size() > 0 and hand.size() < max_hand_size:
		var card = deck.pop_front()
		hand.append(card)
		Events.card_drawn.emit(card, hand.size() - 1)
		return true
	elif deck.size() == 0 and discard_pile.size() > 0:
		# Reshuffle discard pile into deck
		deck = discard_pile.duplicate()
		discard_pile.clear()
		deck.shuffle()
		return draw_card()
	return false

func discard_card(card_index: int):
	if card_index >= 0 and card_index < hand.size():
		var card = hand[card_index]
		hand.remove_at(card_index)
		discard_pile.append(card)
		Events.card_discarded.emit(card)

func get_card_at(index: int) -> CardResource:
	if index >= 0 and index < hand.size():
		return hand[index]
	return null

func get_sorted_deck_contents() -> Array[CardResource]:
	var sorted_cards: Array[CardResource] = []
	for card in deck:
		if card is CardResource:
			sorted_cards.append(card)
	# Sort by name
	sorted_cards.sort_custom(func(a, b): return a.name < b.name)
	return sorted_cards

func get_discard_contents() -> Array[CardResource]:
	var cards: Array[CardResource] = []
	for card in discard_pile:
		if card is CardResource:
			cards.append(card)
	return cards
