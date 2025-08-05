extends Control  # Make sure this matches your root node type

func _ready():
	print("=== DEBUG INFO ===")
	print("Root node: ", name)
	print("Root node type: ", get_class())
	
	print("\nDirect children:")
	for child in get_children():
		print("- Name: '", child.name, "' Type: ", child.get_class())
	
	print("\nAll buttons found:")
	var all_buttons = find_children("*", "Button", true, false)
	for button in all_buttons:
		print("- Button: '", button.name, "' Text: '", button.text, "'")
	
	# Try to connect after we can see what exists
	connect_buttons()

func connect_buttons():
	# Method 1: Try exact names
	var start_btn = get_node_or_null("StartPuzzleButton")  # Replace with actual name
	var dialogue_btn = get_node_or_null("DialogueButton")  # Replace with actual name
	
	print("\nConnection attempts:")
	print("Start button found: ", start_btn != null)
	print("Dialogue button found: ", dialogue_btn != null)
	
	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)
	if dialogue_btn:
		dialogue_btn.pressed.connect(_on_dialogue_pressed)

func _on_start_pressed():
	print("Start button pressed!")
	get_tree().change_scene_to_file("res://SlidePuzzle.tscn")

func _on_dialogue_pressed():
	print("Dialogue button pressed!")
	get_tree().change_scene_to_file("res://dialogue_system_01.tscn")
