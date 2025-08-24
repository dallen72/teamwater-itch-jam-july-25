extends Control

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if (Global.is_within_context_of_game_popup == true):
				hide_credits()
			else:
				get_tree().quit()
		

# on ready, call a function that shows a button in the ui that says "click to start game"
func _ready():
	$Menu/StartGame.connect("pressed", start_game)
	$Menu/CreditsButton.connect("pressed", show_credits)


# when the "click to start game" button is confirmed, the scene is changed to the level_1 scene in the Levels directory
func start_game():
	# Reset energy to starting value
	PlayerEnergy.reset_energy()
	# not working, should be godot 4 syntax
	Global.change_level(1)


func show_credits():
	$Menu/Credits.show()
	Global.is_within_context_of_game_popup = true
	
	
func hide_credits():
	$Menu/Credits.hide()
	Global.is_within_context_of_game_popup = false


func _on_close_credits_button_pressed() -> void:
	hide_credits()
