extends TextureRect

var value: int = 0
var grid_pos: Vector2
var puzzle_manager = null
var is_dragging := false
var drag_offset := Vector2.ZERO
var original_position := Vector2.ZERO

func setup(val: int, pos: Vector2, tile_size: int, manager):
	value = val
	grid_pos = pos
	puzzle_manager = manager
	custom_minimum_size = Vector2(tile_size, tile_size)
	expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	update_appearance()

func update_appearance():
	if value == 0:
		texture = null
		modulate = Color(0.3, 0.3, 0.3, 0.5)
	else:
		# Set your actual image here, e.g.:
		texture = load("res://Images/tile_%d.png" % value)
		modulate = Color.WHITE

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Only allow dragging if this tile can move (adjacent to empty space)
				if puzzle_manager and puzzle_manager.can_tile_move(grid_pos):
					is_dragging = true
					drag_offset = get_global_mouse_position() - global_position
					original_position = position
					# Move to front and add visual feedback
					move_to_front()
					# Scale up slightly and add a subtle shadow effect
					var tween = create_tween()
					tween.set_parallel(true)
					tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
					tween.tween_property(self, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.1)
			else:	
				if is_dragging:
					is_dragging = false
					# Scale back to normal
					var tween = create_tween()
					tween.set_parallel(true)
					tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
					tween.tween_property(self, "modulate", Color.WHITE, 0.15)
					
					# Check if we should move the tile based on mouse position
					if should_move_to_empty():
						if puzzle_manager and puzzle_manager.has_method("try_move_tile"):
							var moved = puzzle_manager.try_move_tile(grid_pos)
							if not moved:
								snap_back()
						else:
							snap_back()
					else:
						snap_back()
	elif event is InputEventMouseMotion and is_dragging:
		# Smoothly follow the mouse with slight easing
		var target_pos = get_global_mouse_position() - drag_offset
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_pos, 0.05)

func should_move_to_empty() -> bool:
	# Check if the mouse is over the empty space when released
	if not puzzle_manager:
		return false
	
	var empty_pos = puzzle_manager.get_empty_position()
	var tile_size = custom_minimum_size.x
	
	# Calculate the empty space's screen position
	var empty_screen_pos = puzzle_manager.grid_container.global_position + Vector2(empty_pos.x * tile_size, empty_pos.y * tile_size)
	var empty_rect = Rect2(empty_screen_pos, Vector2(tile_size, tile_size))
	
	# Check if mouse is within the empty space area
	var mouse_pos = get_global_mouse_position()
	return empty_rect.has_point(mouse_pos)

func snap_back():
	# Reset dragging state
	is_dragging = false
	
	# Calculate the correct position based on grid position
	var tile_size = custom_minimum_size.x
	var target_position = Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)
	
	# Smoothly animate back to the correct grid position with bounce effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_position, 0.25)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(self, "modulate", Color.WHITE if value != 0 else Color(0.3, 0.3, 0.3, 0.5), 0.2)
	
	# Add a subtle bounce effect
	tween.tween_method(func(val): scale = Vector2(val, val), 1.0, 0.95, 0.1)
	tween.tween_method(func(val): scale = Vector2(val, val), 0.95, 1.0, 0.1)
