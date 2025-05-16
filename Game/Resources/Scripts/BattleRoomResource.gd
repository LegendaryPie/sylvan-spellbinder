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
	
func setup_random():
	generate_enemy_types()

func generate_enemy_types():
	enemy_count = 1 if type == RoomType.BOSS else randi_range(1, 3)
	
	match type:
		RoomType.BATTLE:
			enemy_level = 1
			enemy_count = ceil(randf() * 4)
			enemy_types = []
			for i in range(enemy_count):
				enemy_types.append('basic')
		RoomType.ELITE:
			enemy_level = 2
			enemy_count = 2
			enemy_types = []
			for i in range(enemy_count):
				enemy_types.append('basic' if randf() < 0.5 else 'elite')
		RoomType.BOSS:
			enemy_level = 3
			enemy_count = 3
			enemy_types = ['elite', 'elite', 'boss']
	
