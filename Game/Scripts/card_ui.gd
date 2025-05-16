extends Control

var card_resource: CardResource
var hand_index: int = -1

@onready var card_name = $MarginContainer/VBoxContainer/CardName
@onready var card_image = $MarginContainer/VBoxContainer/CardImage
@onready var card_type = $MarginContainer/VBoxContainer/Type
@onready var description = $MarginContainer/VBoxContainer/Description
@onready var energy_cost = $EnergyCost

func _ready():
	gui_input.connect(_on_gui_input)

func set_card(card: CardResource, index: int):
	card_resource = card
	hand_index = index
	
	card_name.text = card.name
	card_type.text = CardResource.CardType.keys()[card.type]
	description.text = card.get_formatted_description()
	energy_cost.text = str(card.energy_cost)
	
	# Set type color based on card type
	match card.type:
		CardResource.CardType.ATTACK:
			card_type.modulate = Color(1, 0.3, 0.3) # Red
		CardResource.CardType.DEFENSE:
			card_type.modulate = Color(0.3, 0.6, 1) # Blue  
		CardResource.CardType.UTILITY:
			card_type.modulate = Color(0.3, 1, 0.5) # Green
			
	# Set name color based on rarity
	match card.rarity:
		CardResource.Rarity.COMMON:
			card_name.modulate = Color.WHITE
		CardResource.Rarity.UNCOMMON:
			card_name.modulate = Color(0.3, 1, 1) # Cyan
		CardResource.Rarity.RARE:
			card_name.modulate = Color(1, 0.6, 0.1) # Orange
		CardResource.Rarity.LEGENDARY:
			card_name.modulate = Color(1, 0.4, 1) # Purple
	
	if ResourceLoader.exists(card.texture_path):
		card_image.texture = load(card.texture_path)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Events.card_clicked.emit(hand_index)

func highlight(active: bool):
	modulate = Color(1.5, 1.5, 1.5, 1.0) if active else Color.WHITE
