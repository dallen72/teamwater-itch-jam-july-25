extends Control

# change the scene to the next level
func _on_temporary_next_level_button_pressed():
	# if the scene exists, load it. the res:// should exist. check if the file exists.	
	if (ResourceLoader.exists("res://Levels/level_" + str(Global.level_num + 1) + ".tscn")):
		get_tree().change_scene_to_file("res://Levels/level_" + str(Global.level_num + 1) + ".tscn")
	# if the level doesn't exist, show the end game display
	else:
		$EndGameDisplay.show()
		$TemporaryNextLevelButton.hide()
		$TemporaryWinText.hide()
