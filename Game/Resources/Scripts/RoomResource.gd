extends Resource
class_name RoomResource

enum RoomType {
	BATTLE,
	ELITE,
	TREASURE,
	REST,
	BOSS
}

@export var type: RoomType
@export var title: String
@export var description: String
@export var icon_path: String
@export var completed: bool = false
@export var available: bool = false  # Whether this room can be selected

var type_name: String:
	get:
		match type:
			RoomType.BATTLE: return "Battle"
			RoomType.ELITE: return "Elite"
			RoomType.TREASURE: return "Treasure"
			RoomType.REST: return "Rest"
			RoomType.BOSS: return "Boss"
			_: return "Unknown"

# Store connections to other rooms
@export var connections: Array = []  # Can't use Array[RoomResource] due to cyclic reference
var typed_connections: Array[RoomResource]:
	get:
		var typed: Array[RoomResource] = []
		for conn in connections:
			if conn is RoomResource:
				typed.append(conn)
		return typed

# Position in the map (normalized 0-1 coordinates)
@export var position: Vector2

# Reward properties
@export var gold_reward: int = 0
@export var health_bonus: int = 0
@export var card_reward: bool = false
@export var artifact_reward: bool = false

func can_connect_to(other_room: RoomResource) -> bool:
	return connections.has(other_room)

func mark_completed():
	completed = true
	# Make connected rooms available
	for room in connections:
		if room is RoomResource:
			room.available = true

func setup_rewards():
	match type:
		RoomType.BATTLE:
			gold_reward = randi_range(10, 20)
			card_reward = true
		RoomType.ELITE:
			gold_reward = randi_range(25, 40)
			card_reward = true
			artifact_reward = randf() > 0.5
		RoomType.TREASURE:
			gold_reward = randi_range(40, 60)
			artifact_reward = true
		RoomType.REST:
			health_bonus = 30
		RoomType.BOSS:
			gold_reward = randi_range(80, 100)
			card_reward = true
			artifact_reward = true

func setup_random():
	if type:
		match type:
			RoomType.TREASURE:
				title = "Random"
			RoomType.REST:
				title = "Random"
				

func complete_room():
	completed = true
	# Make connected rooms available
	for room in typed_connections:
		room.available = true

func can_enter() -> bool:
	return available and not completed
