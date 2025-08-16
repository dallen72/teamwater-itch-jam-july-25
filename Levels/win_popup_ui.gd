extends Control

func _ready():
	# Wait for the first frame to ensure size is available
	await get_tree().process_frame
	# Register this UI area with the global click handler
	Global.register_ui_area(self, size)

func _gui_input(event):
	# Consume all input events to prevent them from reaching the level below
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		accept_event()
		return

# change the scene to the next level
func _on_temporary_next_level_button_pressed():
	# if the scene exists, load it. the res:// should exist. check if the file exists.	
	if (ResourceLoader.exists("res://Levels/level_" + str(Global.level_num + 1) + ".tscn")):
		Global.change_level(Global.level_num + 1)
	# if the level doesn't exist, show the end game display
	else:
		$EndGameDisplay.show()
		$TemporaryNextLevelButton.hide()
		$TemporaryWinText.hide()
