extends Control

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
	$StartGame.connect("pressed", start_game)
	# Connect to energy system and update UI
	Global.energy_changed.connect(_on_energy_changed)
	# Set initial energy display
	update_energy_display()


# when the "click to start game" button is confirmed, the scene is changed to the level_1 scene in the Levels directory
func start_game():
	# Reset energy to starting value
	PlayerEnergy.reset_energy()
	# not working, should be godot 4 syntax
	Global.change_level(1)


# Update energy display in the UI
func update_energy_display():
	var energy_label = $LineEnergyBackground/RichTextLabel
	if energy_label:
		energy_label.text = "Line Energy: " + str(PlayerEnergy.get_energy())

# Called when energy changes
func _on_energy_changed(new_energy: int):
	update_energy_display()
	
