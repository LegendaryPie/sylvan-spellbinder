extends RoomResource
class_name BattleRoomResource

# Enemy configuration
@export var enemy_count: int = 1
@export var enemy_level: int = 1
@export var enemy_types: Array[String] = []

@export var enemy_pool: Array[Resource] = []  # Array of EnemyResource
@export var num_enemies: int = 3
@export var min_level: int = 1  # Minimum enemy level
@export var is_elite: bool = false  # Whether this is an elite battle
@export var rewards: Dictionary = {
	"gold": Vector2i(50, 100),  # min-max gold
	"card_rewards": 3,  # number of cards to choose from
}

func _init():
	type = RoomType.BATTLE

func generate_enemies():
	enemy_count = 1 if type == RoomType.BOSS else randi_range(1, 3)
	
	match type:
		RoomType.BATTLE:
			enemy_level = 1
		RoomType.ELITE:
			enemy_level = 2
			enemy_count = 2
		RoomType.BOSS:
			enemy_level = 3
			enemy_count = 1
	
	# TODO: Replace with actual enemy types from the game
	var possible_enemies = ["Goblin", "Skeleton", "Slime", "Bat", "Spider"]
	enemy_types.clear()
	
	for i in range(enemy_count):
		enemy_types.append(possible_enemies[randi() % possible_enemies.size()])
