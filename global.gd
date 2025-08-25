extends Node

var level_num : int = 0
var input_enabled : bool = true
var is_within_context_of_game_popup : bool = false
var SHOVEL_IMAGE_HEIGHT = 80

# Global variable to store the selected path
var placed_nodes : Array = []

var Z_INDEX_DITCH : int = 1
var Z_INDEX_RIVER : int = 2
var Z_INDEX_SCENERY_BEHIND : int = 3
var Z_INDEX_SCENERY : int = 5
var Z_INDEX_UI : int = 10
var NODE_COLLISION_RADIUS : int = 10



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
	


# Function to update the global selected path
func update_placed_nodes(new_path: Array):
	placed_nodes = new_path.duplicate()

# Function to clear the global selected path
func clear_placed_nodes():
	placed_nodes.clear()


func _input(event):
	handle_input(event)
	

func handle_input(event):
	if (not input_enabled):
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if (Global.is_within_context_of_game_popup == false):
				print("Escape key pressed in Global - exiting game")
				get_tree().quit()
				return
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
	clear_placed_nodes()
	# Obstacle cache removed - no longer needed
	get_tree().change_scene_to_file("res://Levels/level_" + str(level_num) + ".tscn")
