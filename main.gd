extends Node2D

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _process(_delta):
	# when the escape key is pressed, exit the game
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
