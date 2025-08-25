extends Node

var level_num : int = 0
var input_enabled : bool = true
var is_within_context_of_game_popup : bool = false
var SHOVEL_IMAGE_HEIGHT = 80

# Global variable to store the selected path
var selected_path : Array = []

var Z_INDEX_DITCH : int = 1
var Z_INDEX_RIVER : int = 2
var Z_INDEX_SCENERY_BEHIND : int = 3
var Z_INDEX_SCENERY : int = 5
var Z_INDEX_UI : int = 10

# Cursor textures
var shovel_cursor_texture : Texture2D
var x_cursor_texture : Texture2D

@warning_ignore("unused_signal")
signal dialogue_finished
@warning_ignore("unused_signal")
signal energy_changed(new_energy: int)
@warning_ignore("unused_signal")
signal level_clicked(click_position: Vector2)
@warning_ignore("unused_signal")
signal ui_clicked(click_position: Vector2)
@warning_ignore("unused_signal")
signal right_clicked(click_position: Vector2)
@warning_ignore("unused_signal")
signal level_completed
@warning_ignore("unused_signal")
signal level_win_animation_finished
@warning_ignore("unused_signal")
signal left_click_tutorial_finished

# Global click handler
var ui_areas = []

func _ready():
	# Connect to input events to ensure escape key works
	set_process_input(true)
	print("Global autoload ready - input processing enabled")
	
	# Load cursor textures
	_load_cursor_textures()
	
	# Start the cursor check timer
	_start_cursor_check_timer()

func _load_cursor_textures():
	# Load the shovel texture
	shovel_cursor_texture = load("res://Assets/nomad/shovel.png")
	if not shovel_cursor_texture:
		print("Warning: Could not load shovel.png for custom cursor")
	
	# Load the x cursor texture
	x_cursor_texture = load("res://Assets/x_cursor.png")
	if not x_cursor_texture:
		print("Warning: Could not load x_cursor.png for custom cursor")

func _start_cursor_check_timer():
	# Create a timer to check cursor position periodically
	var timer = Timer.new()
	timer.name = "CursorCheckTimer"
	timer.wait_time = 0.1  # Check every 100ms
	timer.timeout.connect(_check_cursor_position)
	add_child(timer)
	timer.start()
	print("Cursor check timer started")

func _check_cursor_position():
	# Get current mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Check if the position is valid for node placement
	if _is_position_valid_for_placement(mouse_pos):
		_set_shovel_cursor()
	else:
		_set_x_cursor()

func _is_position_valid_for_placement(pos: Vector2) -> bool:
	# Check if we have enough energy to place a node at this position
	if selected_path.size() > 0:
		var last_node_pos = selected_path[-1].position
		
		# Use the NodePlacementValidator to check if the connection is valid
		if not NodePlacementValidator.is_connection_valid(last_node_pos, pos, PlayerEnergy.get_energy()):
			return false
	else:
		# If no selected path, just check if the position itself is valid
		if not NodePlacementValidator.can_place_node_at_position(pos):
			return false
	
	return true



func _set_shovel_cursor():
	if shovel_cursor_texture:
		Input.set_custom_mouse_cursor(shovel_cursor_texture, Input.CURSOR_ARROW, Vector2(0, SHOVEL_IMAGE_HEIGHT))

func _set_x_cursor():
	if x_cursor_texture:
		Input.set_custom_mouse_cursor(x_cursor_texture, Input.CURSOR_ARROW, Vector2(16, 16))



# Function to update the global selected path
func update_selected_path(new_path: Array):
	selected_path = new_path.duplicate()

# Function to clear the global selected path
func clear_selected_path():
	selected_path.clear()


func _input(event):
	# Handle escape key directly here as a fallback
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if (Global.is_within_context_of_game_popup == false):
				print("Escape key pressed in Global - exiting game")
				get_tree().quit()
				return


func handle_input(event):
	if (not input_enabled):
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("Escape key pressed - exiting game")
			get_tree().quit()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Mouse left-click detected at: ", event.position)
			# Check if this click is in a UI area first
			if is_click_in_ui_area(event.position):
				print("UI click detected at: ", event.position)
				# For UI clicks, just emit the signal and let the UI handle it
				ui_clicked.emit(event.position)
				# Don't consume the event - let the UI elements handle their own input
				return
			else:
				print("Level click detected at: ", event.position)
				# Only emit level_clicked if not in UI area
				level_clicked.emit(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			print("Mouse right-click detected at: ", event.position)
			# Right-clicks always go to the level (not UI)
			right_clicked.emit(event.position)

# Check if a click position is within any registered UI area
func is_click_in_ui_area(click_position: Vector2) -> bool:
	for ui_area in ui_areas:
		if is_point_in_ui_area(click_position, ui_area):
			return true
	return false

# Check if a point is within a UI area
func is_point_in_ui_area(point: Vector2, ui_area: Dictionary) -> bool:
	var rect = ui_area.rect
	var global_pos = ui_area.global_position
	
	return (point.x >= global_pos.x and 
			point.x <= global_pos.x + rect.x and
			point.y >= global_pos.y and 
			point.y <= global_pos.y + rect.y)

# Register a UI area to be checked for clicks
func register_ui_area(ui_area: Control, rect: Vector2):
	var area_data = {
		"control": ui_area,
		"rect": rect,
		"global_position": ui_area.global_position
	}
	ui_areas.append(area_data)
	print("Registered UI area: ", ui_area.name, " with size: ", rect, " at global pos: ", ui_area.global_position)
	print("Total UI areas registered: ", ui_areas.size())

# Unregister a UI area
func unregister_ui_area(ui_area: Control):
	for i in range(ui_areas.size()):
		if ui_areas[i].control == ui_area:
			ui_areas.remove_at(i)
			break

# optional parameter for level number
func change_level(_next_level):
	level_num = _next_level
	ui_areas = []
	# Selected path mirror removed - no longer needed
	# Clear the global selected path when changing levels
	clear_selected_path()
	# Clear the obstacle cache when changing levels
	NodePlacementValidator.clear_obstacle_cache()
	get_tree().change_scene_to_file("res://Levels/level_" + str(level_num) + ".tscn")
