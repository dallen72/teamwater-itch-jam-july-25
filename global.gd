extends Node

var level_num : int = 0

@warning_ignore("unused_signal")
signal dialogue_finished
@warning_ignore("unused_signal")
signal energy_changed(new_energy: int)
@warning_ignore("unused_signal")
signal level_clicked(click_position: Vector2)
@warning_ignore("unused_signal")
signal ui_clicked(click_position: Vector2)

# Global click handler
var ui_areas = []

func handle_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_mouse_click(event.position)

# Handle mouse clicks and determine if they're in UI areas
func handle_mouse_click(click_position: Vector2):
	# Check if click is in any UI area
	for ui_area in ui_areas:
		if is_point_in_ui_area(click_position, ui_area):
			ui_clicked.emit(click_position)
			return
	
	# If not in UI area, emit level click signal
	level_clicked.emit(click_position)

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

# Unregister a UI area
func unregister_ui_area(ui_area: Control):
	for i in range(ui_areas.size()):
		if ui_areas[i].control == ui_area:
			ui_areas.remove_at(i)
			break

# optional parameter for level number
func change_level(_next_level):
	level_num = _next_level
	get_tree().change_scene_to_file("res://Levels/level_" + str(level_num) + ".tscn")
