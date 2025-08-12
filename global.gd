extends Node

var level_num : int = 0

signal dialogue_finished


func handle_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()


# optional parameter for level number
func change_level(_next_level):
	level_num = _next_level
	get_tree().change_scene_to_file("res://Levels/level_" + str(level_num) + ".tscn")
