extends Node2D

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()

func _process(_delta):
	# when the escape key is pressed, exit the game
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		

# on ready, call a function that shows a button in the ui that says "click to start game"
func _ready():
	show_main_menu_popup()
	# Connect to energy system and update UI
	PlayerEnergy.energy_changed.connect(_on_energy_changed)
	# Set initial energy display
	update_energy_display()


func show_main_menu_popup():
	var button = Button.new()
	button.text = "Click to start game"
	button.connect("pressed", start_game)
	add_child(button)
	# center the button in the screen
	button.position = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y / 2)


# when the "click to start game" button is confirmed, the scene is changed to the level_1 scene in the Levels directory
func start_game():
	# Reset energy to starting value
	PlayerEnergy.reset_energy()
	# not working, should be godot 4 syntax
	get_tree().change_scene_to_file("res://Levels/level_1.tscn")

# Update energy display in the UI
func update_energy_display():
	var energy_label = $LineEnergyBackground/RichTextLabel
	if energy_label:
		energy_label.text = "Line Energy: " + str(PlayerEnergy.get_energy())

# Called when energy changes
func _on_energy_changed(new_energy: int):
	update_energy_display()
	
