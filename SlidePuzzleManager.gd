extends Control  # or Node2D, depending on your scene structure

# Grid size
const GRID_SIZE = 3
const TILE_SIZE = 100

# Grid data - 0 represents empty space
var grid = [
	[1, 2, 3],
	[4, 5, 6],
	[7, 8, 0]
]

# Solved state for comparison
var solved_grid = [
	[1, 2, 3],
	[4, 0, 6],
	[7, 8, 5]
]

var empty_pos = Vector2(2, 2)
var tile_instances = []
var selected_tile_pos = Vector2(-1, -1)  # For keyboard navigation
@onready var grid_container = $GridContainer

func _ready():
	setup_grid_container()
	setup_puzzle()
	scramble_puzzle(50)  # Scramble with 50 moves
	
	# Make sure this node can receive input
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.pressed:
		handle_keyboard_input(event.keycode)

func handle_keyboard_input(keycode):
	var move_direction = Vector2.ZERO
	
	# Determine movement direction based on key pressed
	match keycode:
		KEY_W, KEY_UP:
			move_direction = Vector2(0, 1)  # Move tile DOWN to fill empty space UP
		KEY_S, KEY_DOWN:
			move_direction = Vector2(0, -1)  # Move tile UP to fill empty space DOWN
		KEY_A, KEY_LEFT:
			move_direction = Vector2(1, 0)   # Move tile RIGHT to fill empty space LEFT
		KEY_D, KEY_RIGHT:
			move_direction = Vector2(-1, 0)  # Move tile LEFT to fill empty space RIGHT
		_:
			return
	
	# Calculate which tile should move into the empty space
	var target_tile_pos = empty_pos + move_direction
	
	# Check if the target position is valid and try to move the tile
	if is_valid_position(target_tile_pos):
		try_move_tile(target_tile_pos)

func setup_grid_container():
	# Configure GridContainer for 3x3 layout
	grid_container.columns = GRID_SIZE
	
	# Set minimum size for the grid container
	grid_container.custom_minimum_size = Vector2(GRID_SIZE * TILE_SIZE, GRID_SIZE * TILE_SIZE)
	
	# Optional: Add some spacing between tiles
	grid_container.add_theme_constant_override("h_separation", 2)
	grid_container.add_theme_constant_override("v_separation", 2)

func setup_puzzle():
	# Clear any existing children
	for child in grid_container.get_children():
		child.queue_free()
	
	tile_instances.clear()
	
	# Create tiles using your Tile.tscn
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile_scene = preload("res://Tile.tscn")
			var tile = tile_scene.instantiate()
			var value = grid[y][x]
			tile.setup(value, Vector2(x, y), TILE_SIZE, self)
			tile_instances.append(tile)
			grid_container.add_child(tile)

func can_tile_move(tile_pos: Vector2) -> bool:
	# Check if the tile is adjacent to the empty space
	return is_adjacent_to_empty(tile_pos)

func get_empty_position() -> Vector2:
	return empty_pos

func try_move_tile(tile_pos: Vector2) -> bool:
	if is_adjacent_to_empty(tile_pos):
		# Get the tile value at the clicked position
		var tile_value = grid[tile_pos.y][tile_pos.x]
		
		# Find the actual tile instances that need to be updated
		var moving_tile = get_tile_at_position(tile_pos)
		var empty_tile = get_tile_at_position(empty_pos)
		
		# Swap tile with empty space in the grid
		grid[empty_pos.y][empty_pos.x] = tile_value
		grid[tile_pos.y][tile_pos.x] = 0
		
		# Store old empty position for animation
		var old_empty_pos = empty_pos
		
		# Update empty position
		empty_pos = tile_pos
		
		# Only update the two tiles that are actually moving
		if moving_tile and empty_tile:
			animate_tile_swap(moving_tile, empty_tile, tile_pos, old_empty_pos)
		
		# Check if puzzle is solved
		if is_solved():
			print("Puzzle Solved!")
			show_victory_message()
		
		return true
	return false

func get_tile_at_position(pos: Vector2):
	# Find the tile instance at the given grid position
	for tile in tile_instances:
		if tile.grid_pos == pos:
			return tile
	return null

func animate_tile_swap(moving_tile, empty_tile, new_moving_pos: Vector2, new_empty_pos: Vector2):
	# Update the tile data
	moving_tile.value = 0  # This tile becomes empty
	moving_tile.grid_pos = new_moving_pos
	moving_tile.update_appearance()
	
	empty_tile.value = grid[new_empty_pos.y][new_empty_pos.x]  # This tile gets the moved value
	empty_tile.grid_pos = new_empty_pos
	empty_tile.update_appearance()
	
	# Calculate target positions
	var moving_target = Vector2(new_moving_pos.x * TILE_SIZE, new_moving_pos.y * TILE_SIZE)
	var empty_target = Vector2(new_empty_pos.x * TILE_SIZE, new_empty_pos.y * TILE_SIZE)
	
	# Animate both tiles smoothly to their new positions
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple animations at once
	tween.tween_property(moving_tile, "position", moving_target, 0.2)
	tween.tween_property(empty_tile, "position", empty_target, 0.2)

func update_all_tiles():
	# This function is now only used for initial setup and major resets
	# Normal moves use animate_tile_swap() instead
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var index = y * GRID_SIZE + x
			if index < tile_instances.size():
				var tile = tile_instances[index]
				var new_value = grid[y][x]
				tile.value = new_value
				tile.grid_pos = Vector2(x, y)
				tile.update_appearance()
				
				# Set position immediately (no animation for bulk updates)
				var target_position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				tile.position = target_position

func is_adjacent_to_empty(pos: Vector2) -> bool:
	var distance = abs(pos.x - empty_pos.x) + abs(pos.y - empty_pos.y)
	return distance == 1

func is_solved() -> bool:
	# Compare current grid with solved state
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if grid[y][x] != solved_grid[y][x]:
				return false
	return true

func scramble_puzzle(num_moves: int):
	# Scramble by making random valid moves
	for i in range(num_moves):
		var valid_moves = get_valid_moves()
		if valid_moves.size() > 0:
			var random_move = valid_moves[randi() % valid_moves.size()]
			try_move_tile(random_move)

func get_valid_moves() -> Array:
	var moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
	
	for direction in directions:
		var new_pos = empty_pos + direction
		if is_valid_position(new_pos):
			moves.append(new_pos)
	
	return moves

func is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

func show_victory_message():
	# Add your victory celebration here
	var label = Label.new()
	label.text = "Puzzle Solved!"
	label.add_theme_font_size_override("font_size", 32)
	label.position = Vector2(50, 50)
	add_child(label)
	
	# Optional: Add restart button
	var button = Button.new()
	button.text = "New Puzzle"
	button.position = Vector2(50, 100)
	button.pressed.connect(restart_puzzle)
	add_child(button)

func restart_puzzle():
	# Clean up victory UI
	for child in get_children():
		if child is Label or child is Button:
			child.queue_free()
	
	# Reset grid to solved state
	grid = [
		[1, 2, 3],
		[4, 0, 6],
		[7, 8, 5]
	]
	empty_pos = Vector2(2, 2)
	
	# Update all tiles first, then scramble
	update_all_tiles()
	scramble_puzzle(50)
