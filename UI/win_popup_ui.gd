extends Control

func _ready():
	# Wait for the first frame to ensure size is available
	await get_tree().process_frame
	$NextLevelPromptBox.connect("show", _on_show)


func _on_show():
	Global.register_ui_area(self, size)
	$NextLevelPromptBox.connect("hide", _on_hide)


func _on_hide():
	Global.unregister_ui_area(self)


# change the scene to the next level
func _on_temporary_next_level_button_pressed():
	# if the scene exists, load it. the res:// should exist. check if the file exists.	
	if (ResourceLoader.exists("res://Levels/level_" + str(Global.level_num + 1) + ".tscn")):
		Global.change_level(Global.level_num + 1)
	# if the level doesn't exist, show the end game display
	else:
		$EndGameDisplay.show()
		$NextLevelPromptBox.hide()
		Global.unregister_ui_area(self)
