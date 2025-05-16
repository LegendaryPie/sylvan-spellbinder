extends CanvasLayer

signal room_selected(room: RoomResource)

const ROOM_SCENE = preload("res://Game/Scenes/map_room.tscn")
const LINE_COLOR = Color(0.7, 0.7, 0.7)
const LINE_WIDTH = 2.0

var rooms: Array[RoomResource] = []
var current_floor: int = 1
var map_nodes: Dictionary = {}  # RoomResource -> MapRoom node
var boss_defeated: bool = false

@onready var map_content = $ScrollContainer/MapContent
@onready var lines_container = $ScrollContainer/MapContent/Lines
@onready var rooms_container = $ScrollContainer/MapContent/Rooms

func _ready():
	generate_map()

func generate_map():
	# Clear existing map
	for child in lines_container.get_children():
		child.queue_free()
	for child in rooms_container.get_children():
		child.queue_free()
	map_nodes.clear()
	
	# Generate room layout
	rooms = generate_floor_rooms(current_floor)
		# Draw connections
	for room in rooms:
		for connected_room in room.typed_connections:
			draw_connection(room, connected_room)
	
	# Create room nodes
	for room in rooms:
		create_room_node(room)
	
	# Make starting rooms available
	for room in rooms:
		if room.position.y < 0.1:  # Rooms in first row
			room.available = true
	
	# Update room visuals
	update_room_states()

func generate_floor_rooms(floor_num: int) -> Array[RoomResource]:
	var generated_rooms: Array[RoomResource] = []
	var num_rows = 4
	var rooms_per_row = 3
	var row_spacing = 1.0 / (num_rows - 1)
	var col_spacing = 1.0 / (rooms_per_row + 1)
	
	# Generate rooms for each row
	for row in range(num_rows):
		var num_rooms = rooms_per_row if row > 0 and row < num_rows - 1 else 1
		for col in range(num_rooms):
			var room: RoomResource
			
			if row == num_rows - 1:
				# Last row is always a boss
				room = BattleRoomResource.new()
				room.type = RoomResource.RoomType.BOSS
			else:
				room = create_random_room()
				# Increase chance of elite and treasure rooms based on floor number
				if room.type == RoomResource.RoomType.ELITE:
					room.type = RoomResource.RoomType.BATTLE if randf() > (0.1 * floor_num) else RoomResource.RoomType.ELITE
			
			var x = col_spacing * (col + 1)
			if num_rooms == 1:
				x = 0.5  # Center the room
			room.position = Vector2(x, row * row_spacing)
			
			# Setup rewards based on room type and floor number
			_assign_room_rewards(room, floor_num)
			if room is BattleRoomResource:
				room.generate_enemies()
				
			generated_rooms.append(room)
		# Connect rooms between adjacent rows
	for row in range(num_rows - 1):
		var current_row_rooms = generated_rooms.filter(func(r): return r.position.y == row * row_spacing)
		var next_row_rooms = generated_rooms.filter(func(r): return r.position.y == (row + 1) * row_spacing)
		
		# Connect each room to 1-2 rooms in the next row
		for room in current_row_rooms:
			var possible_connections = next_row_rooms.duplicate()
			possible_connections.sort_custom(func(a, b): 
				return a.position.distance_to(room.position) < b.position.distance_to(room.position)
			)
			
			# Connect to closest room and maybe second closest
			if possible_connections.size() > 0:
				room.connections.append(possible_connections[0])
				if randf() > 0.3 and possible_connections.size() > 1:  # 70% chance for second connection
					room.connections.append(possible_connections[1])
	
	_ensure_valid_paths()
	return generated_rooms

func create_random_room() -> RoomResource:
	var room_types = [
		{"type": RoomResource.RoomType.BATTLE, "weight": 5},
		{"type": RoomResource.RoomType.ELITE, "weight": 2},
		{"type": RoomResource.RoomType.TREASURE, "weight": 2},
		{"type": RoomResource.RoomType.REST, "weight": 2}
	]
	
	var total_weight = 0
	for type in room_types:
		total_weight += type.weight
	
	var roll = randf() * total_weight
	var running_total = 0
	
	for type in room_types:
		running_total += type.weight
		if roll <= running_total:
			var room = BattleRoomResource.new() if type.type == RoomResource.RoomType.BATTLE or type.type == RoomResource.RoomType.ELITE else RoomResource.new()
			room.type = type.type
			return room
	
	return RoomResource.new()  # Fallback

func draw_connection(from_room: RoomResource, to_room: RoomResource):
	var line = Line2D.new()
	line.default_color = LINE_COLOR
	line.width = LINE_WIDTH
	
	var start_pos = from_room.position * map_content.size
	var end_pos = to_room.position * map_content.size
	
	line.add_point(start_pos)
	line.add_point(end_pos)
	
	lines_container.add_child(line)

func create_room_node(room: RoomResource):
	var room_node = ROOM_SCENE.instantiate()
	rooms_container.add_child(room_node)
	room_node.position = room.position * map_content.size
	room_node.setup(room)
	room_node.room_clicked.connect(_on_room_clicked)
	map_nodes[room] = room_node

func update_room_states():
	for room in rooms:
		var node = map_nodes.get(room)
		if node:
			node.update_state()

func _on_room_clicked(room: RoomResource):
	if room.can_enter():
		# Special handling for boss rooms
		if room.type == RoomResource.RoomType.BOSS:
			var all_rooms_completed = true
			for r in rooms:
				if r.type != RoomResource.RoomType.BOSS and not r.completed:
					all_rooms_completed = false
					break
			
			if not all_rooms_completed:
				# TODO: Show warning that other rooms should be completed first
				return
		
		room_selected.emit(room)

func _assign_room_rewards(room: RoomResource, floor_num: int):
	var floor_multiplier = 1.0 + (floor_num - 1) * 0.5
	
	room.setup_rewards()
	match room.type:
		RoomResource.RoomType.BATTLE:
			room.gold_reward = int(randi_range(10, 20) * floor_multiplier)
		RoomResource.RoomType.ELITE:
			room.gold_reward = int(randi_range(25, 40) * floor_multiplier)
			room.artifact_reward = randf() > 0.7  # 30% chance
		RoomResource.RoomType.TREASURE:
			room.gold_reward = int(randi_range(40, 60) * floor_multiplier)
		RoomResource.RoomType.REST:
			room.health_bonus = int(30 * floor_multiplier)
		RoomResource.RoomType.BOSS:
			room.gold_reward = int(randi_range(80, 100) * floor_multiplier)

func _validate_room_connections() -> bool:
	var all_rooms_reachable = true
	var visited = {}
	var start_rooms = []
	
	# Find start rooms (rooms in first row)
	for room in rooms:
		visited[room] = false
		if room.position.y < 0.1:
			start_rooms.append(room)
	
	# Run DFS from each start room
	for start in start_rooms:
		_dfs_visit(start, visited)
	
	# Check if all rooms are reachable
	for room in rooms:
		if not visited[room]:
			all_rooms_reachable = false
			break
	
	return all_rooms_reachable

func _dfs_visit(room: RoomResource, visited: Dictionary):
	visited[room] = true
	for next_room in room.typed_connections:
		if not visited[next_room]:
			_dfs_visit(next_room, visited)

func _ensure_valid_paths():
	# Keep adding connections until all rooms are reachable
	while not _validate_room_connections():
		var unreachable_rooms = []
		var visited = {}
		
		# Initialize visited map
		for room in rooms:
			visited[room] = false
		
		# Find reachable rooms from start
		for room in rooms:
			if room.position.y < 0.1:
				_dfs_visit(room, visited)
		
		# Collect unreachable rooms
		for room in rooms:
			if not visited[room]:
				unreachable_rooms.append(room)
		
		# Add new connections to make unreachable rooms reachable
		for room in unreachable_rooms:
			var possible_connections = []
			for other in rooms:
				if visited[other] and other != room:
					var distance = other.position.distance_to(room.position)
					if distance < 0.4:  # Adjust this value to control max connection distance
						possible_connections.append(other)
			
			if possible_connections.size() > 0:
				var connect_to = possible_connections[randi() % possible_connections.size()]
				connect_to.connections.append(room)
				visited[room] = true
