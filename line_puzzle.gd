extends Node2D
class_name GameManager

# Game configuration
@export var grid_size: int = 5
@export var node_spacing: float = 80.0
@export var node_radius: float = 15.0
@export var connection_width: float = 8.0
@export var click_tolerance: float = 30.0

# Node and connection data
var nodes: Array[Dictionary] = []
var connections: Array[Dictionary] = []
var selected_node: Dictionary = {}

# Game entities
var entities: Array[Dictionary] = []

# Game state
var score: int = 0
var game_won: bool = false

# Signals
signal node_selected(node: Dictionary)
signal connection_created(from_node: Dictionary, to_node: Dictionary)
signal water_flow_updated()
signal game_completed(final_score: int)

func _ready():
	initialize_game()

func initialize_game():
	"""Initialize the game with nodes and entities"""
	create_grid_nodes()
	setup_entities()
	update_water_flow()

func create_grid_nodes():
	"""Generate the 5x5 grid of nodes"""
	nodes.clear()
	
	for y in range(grid_size):
		for x in range(grid_size):
			var node = {
				"id": str(x) + "-" + str(y),
				"grid_x": x,
				"grid_y": y,
				"world_pos": Vector2(x * node_spacing, y * node_spacing),
				"has_water": false,
				"is_selected": false
			}
			
			# Starting position has water (nomad position)
			if x == 2 and y == 0:
				node.has_water = true
			
			nodes.append(node)

func setup_entities():
	"""Setup game entities (cows, children, nomad)"""
	entities.clear()
	
	# Add entities at specific grid positions
	entities.append({
		"type": "nomad",
		"grid_x": 2,
		"grid_y": 0,
		"has_water": true
	})
	
	entities.append({
		"type": "cow",
		"grid_x": 1,
		"grid_y": 1,
		"has_water": false
	})
	
	entities.append({
		"type": "cow",
		"grid_x": 3,
		"grid_y": 2,
		"has_water": false
	})
	
	entities.append({
		"type": "child",
		"grid_x": 0,
		"grid_y": 4,
		"has_water": false
	})
	
	entities.append({
		"type": "child",
		"grid_x": 4,
		"grid_y": 3,
		"has_water": false
	})

func _input(event):
	"""Handle mouse input for node selection and connection"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_click(event.position)

func handle_click(click_pos: Vector2):
	"""Handle mouse click for node selection and connection creation"""
	var clicked_node = find_closest_node(click_pos)
	
	if clicked_node.is_empty():
		# Clicked empty space - deselect current node
		deselect_current_node()
		return
	
	if selected_node.is_empty():
		# No node selected - select the clicked node
		select_node(clicked_node)
	else:
		# Node already selected
		if clicked_node.id == selected_node.id:
			# Clicked same node - deselect
			deselect_current_node()
		else:
			# Try to create connection
			attempt_connection(selected_node, clicked_node)

func find_closest_node(click_pos: Vector2) -> Dictionary:
	"""Find the closest node to the click position within tolerance"""
	var closest_node = {}
	var min_distance = INF
	
	for node in nodes:
		var distance = click_pos.distance_to(node.world_pos)
		if distance < min_distance and distance <= click_tolerance:
			min_distance = distance
			closest_node = node
	
	return closest_node

func select_node(node: Dictionary):
	"""Select a node"""
	selected_node = node
	node.is_selected = true
	node_selected.emit(node)
	queue_redraw()

func deselect_current_node():
	"""Deselect the currently selected node"""
	if not selected_node.is_empty():
		selected_node.is_selected = false
		selected_node = {}
		queue_redraw()

func attempt_connection(from_node: Dictionary, to_node: Dictionary):
	"""Attempt to create a connection between two nodes"""
	# Check if nodes are adjacent
	if not are_nodes_adjacent(from_node, to_node):
		deselect_current_node()
		return
	
	# Check if connection already exists
	if connection_exists(from_node, to_node):
		deselect_current_node()
		return
	
	# Create the connection
	create_connection(from_node, to_node)
	deselect_current_node()

func are_nodes_adjacent(node1: Dictionary, node2: Dictionary) -> bool:
	"""Check if two nodes are adjacent (horizontal or vertical neighbors)"""
	var dx = abs(node1.grid_x - node2.grid_x)
	var dy = abs(node1.grid_y - node2.grid_y)
	return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)

func connection_exists(node1: Dictionary, node2: Dictionary) -> bool:
	"""Check if a connection already exists between two nodes"""
	for connection in connections:
		if (connection.from_id == node1.id and connection.to_id == node2.id) or \
		   (connection.from_id == node2.id and connection.to_id == node1.id):
			return true
	return false

func create_connection(from_node: Dictionary, to_node: Dictionary):
	"""Create a new connection between two nodes"""
	var connection = {
		"from_id": from_node.id,
		"to_id": to_node.id,
		"from_pos": from_node.world_pos,
		"to_pos": to_node.world_pos
	}
	
	connections.append(connection)
	connection_created.emit(from_node, to_node)
	
	# Update water flow and game state
	update_water_flow()
	update_game_state()
	queue_redraw()

func update_water_flow():
	"""Update water flow through the connected network using BFS"""
	# Reset all nodes to no water except starting position
	for node in nodes:
		node.has_water = (node.grid_x == 2 and node.grid_y == 0)
	
	# BFS to spread water through connections
	var queue: Array[Dictionary] = []
	var visited: Array[String] = []
	
	# Start from nodes that have water
	for node in nodes:
		if node.has_water:
			queue.append(node)
			visited.append(node.id)
	
	while not queue.is_empty():
		var current_node = queue.pop_front()
		
		# Check all connections from this node
		for connection in connections:
			var next_node: Dictionary = {}
			
			if connection.from_id == current_node.id:
				next_node = get_node_by_id(connection.to_id)
			elif connection.to_id == current_node.id:
				next_node = get_node_by_id(connection.from_id)
			
			if not next_node.is_empty() and not next_node.id in visited:
				next_node.has_water = true
				visited.append(next_node.id)
				queue.append(next_node)
	
	water_flow_updated.emit()

func get_node_by_id(node_id: String) -> Dictionary:
	"""Get a node by its ID"""
	for node in nodes:
		if node.id == node_id:
			return node
	return {}

func update_game_state():
	"""Update entities and check win condition"""
	# Update entity water status
	for entity in entities:
		var node_at_position = get_node_at_grid_position(entity.grid_x, entity.grid_y)
		if not node_at_position.is_empty():
			entity.has_water = node_at_position.has_water
	
	# Calculate score
	score = 0
	for entity in entities:
		if entity.has_water and entity.type != "nomad":
			score += 10
	
	# Check win condition
	check_win_condition()

func get_node_at_grid_position(grid_x: int, grid_y: int) -> Dictionary:
	"""Get the node at a specific grid position"""
	for node in nodes:
		if node.grid_x == grid_x and node.grid_y == grid_y:
			return node
	return {}

func check_win_condition():
	"""Check if the player has won the game"""
	var entities_needing_water = entities.filter(func(e): return e.type != "nomad")
	var entities_with_water = entities_needing_water.filter(func(e): return e.has_water)
	
	if entities_with_water.size() == entities_needing_water.size() and not game_won:
		game_won = true
		game_completed.emit(score)

func reset_game():
	"""Reset the game to initial state"""
	connections.clear()
	selected_node = {}
	score = 0
	game_won = false
	
	# Reset nodes
	for node in nodes:
		node.has_water = (node.grid_x == 2 and node.grid_y == 0)
		node.is_selected = false
	
	# Reset entities
	for entity in entities:
		entity.has_water = (entity.type == "nomad")
	
	queue_redraw()

func _draw():
	"""Draw the game elements"""
	draw_connections()
	draw_nodes()
	draw_entities()

func draw_connections():
	"""Draw all river connections"""
	for connection in connections:
		draw_line(
			connection.from_pos,
			connection.to_pos,
			Color.BLUE,
			connection_width
		)

func draw_nodes():
	"""Draw all grid nodes"""
	for node in nodes:
		var color = Color.SADDLE_BROWN  # Default dry land color
		
		if node.is_selected:
			color = Color.GOLD
		elif node.has_water:
			color = Color.BLUE
		
		draw_circle(node.world_pos, node_radius, color)
		draw_arc(node.world_pos, node_radius, 0, TAU, 32, Color.BLACK, 2.0)

func draw_entities():
	"""Draw game entities (this is a placeholder - you'd want sprites in a real game)"""
	for entity in entities:
		var pos = Vector2(entity.grid_x * node_spacing, entity.grid_y * node_spacing)
		var color = Color.GREEN if entity.has_water else Color.RED
		
		# Draw a simple representation
		match entity.type:
			"nomad":
				draw_circle(pos + Vector2(0, -25), 8, Color.GOLD)
			"cow":
				draw_rect(Rect2(pos + Vector2(-10, -35), Vector2(20, 15)), color)
			"child":
				draw_circle(pos + Vector2(0, -30), 6, color)

# Utility functions for external access
func get_score() -> int:
	return score

func get_entities_needing_water() -> int:
	var needing_water = entities.filter(func(e): return e.type != "nomad" and not e.has_water)
	return needing_water.size()

func is_game_won() -> bool:
	return game_won
