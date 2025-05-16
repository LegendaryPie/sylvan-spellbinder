extends Control

signal room_clicked(room: RoomResource)

var room_resource: RoomResource

@onready var button = $Button
@onready var icon = $Button/Icon
@onready var title = $Button/Title

func _ready():
	button.pressed.connect(_on_button_pressed)

func setup(room: RoomResource):
	room_resource = room
	
	# Set room type specific appearance
	var room_desc = ""
	match room.type:
		RoomResource.RoomType.BATTLE:
			room_desc = "Battle"
			if room.gold_reward > 0:
				room_desc += "\nGold: " + str(room.gold_reward)
			if room.card_reward:
				room_desc += "\n+ Card"
			button.modulate = Color(0.8, 0.2, 0.2)
		RoomResource.RoomType.ELITE:
			room_desc = "Elite"
			if room.gold_reward > 0:
				room_desc += "\nGold: " + str(room.gold_reward)
			if room.card_reward:
				room_desc += "\n+ Card"
			if room.artifact_reward:
				room_desc += "\n+ Artifact"
			button.modulate = Color(0.8, 0.4, 0.0)
		RoomResource.RoomType.TREASURE:
			room_desc = "Treasure"
			if room.gold_reward > 0:
				room_desc += "\nGold: " + str(room.gold_reward)
			if room.artifact_reward:
				room_desc += "\n+ Artifact"
			button.modulate = Color(0.9, 0.8, 0.0)
		RoomResource.RoomType.REST:
			room_desc = "Rest"
			if room.health_bonus > 0:
				room_desc += "\nHeal: " + str(room.health_bonus)
			button.modulate = Color(0.2, 0.8, 0.2)
		RoomResource.RoomType.BOSS:
			room_desc = "Boss"
			if room.gold_reward > 0:
				room_desc += "\nGold: " + str(room.gold_reward)
			if room.card_reward:
				room_desc += "\n+ Card"
			if room.artifact_reward:
				room_desc += "\n+ Artifact"
			button.modulate = Color(0.8, 0.0, 0.0)
	
	title.text = room_desc
	
	# Load icon if specified
	if room.icon_path and ResourceLoader.exists(room.icon_path):
		icon.texture = load(room.icon_path)
	
	update_state()

func update_state():
	if not room_resource:
		return
		
	button.disabled = not room_resource.available or room_resource.completed
	
	if room_resource.completed:
		button.modulate = Color(0.5, 0.5, 0.5)
	elif not room_resource.available:
		match room_resource.type:
			RoomResource.RoomType.BATTLE:
				button.modulate = Color(0.8, 0.2, 0.2).darkened(.7)
			RoomResource.RoomType.ELITE:
				button.modulate = Color(0.8, 0.4, 0.0).darkened(.7)
			RoomResource.RoomType.TREASURE:
				button.modulate = Color(0.9, 0.8, 0.0).darkened(.7)
			RoomResource.RoomType.REST:
				button.modulate = Color(0.2, 0.8, 0.2).darkened(.7)
			RoomResource.RoomType.BOSS:
				button.modulate = Color(0.8, 0.0, 0.0).darkened(.7)
	elif room_resource.available:
		match room_resource.type:
			RoomResource.RoomType.BATTLE:
				button.modulate = Color(0.8, 0.2, 0.2)
			RoomResource.RoomType.ELITE:
				button.modulate = Color(0.8, 0.4, 0.0)
			RoomResource.RoomType.TREASURE:
				button.modulate = Color(0.9, 0.8, 0.0)
			RoomResource.RoomType.REST:
				button.modulate = Color(0.2, 0.8, 0.2)
			RoomResource.RoomType.BOSS:
				button.modulate = Color(0.8, 0.0, 0.0)

func _on_button_pressed():
	room_clicked.emit(room_resource)
