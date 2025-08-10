# DialogueSystem.gd
extends Control


var dialogue_output = []
var current_dialogue_index = 0
var current_character = "John"


# Signal for when dialogue ends
signal dialogue_finished

#import resource guy.png
var testtexture = load("res://Assets/guy.png") #TODO: fallback

func _ready():
	# Make Function that appends all strings from JSON file
	# Or use JSON file in future for dialogue
	dialogue_output.append("Hello let us start")
	dialogue_output.append("You are creating a river, where water will run through.")
	dialogue_output.append("Start by clicking a node three squares to the right")
	dialogue_output.append("You cannot go through the tree, so you will have to go around.")
	dialogue_output.append("Your goal is to make it to the cow.")
	dialogue_output.append("Using the energy you have available to you.")
	dialogue_output.append("Good luck, see you soon.")

	start_dialogue(current_character, testtexture, dialogue_output)
	$ContinueButton.pressed.connect(_on_continue_pressed)
	#hide_dialogue()

	
# Method 1: Using individual parameters (your current approach)
func start_dialogue(character_name: String, portrait_texture: Texture2D, dialogue_lines: Array):
	current_character = character_name
	dialogue_output = dialogue_lines
	current_dialogue_index = 0
	
	$DialogueBox/CharacterName.text = character_name  # Fixed the bug here
	$DialogueBox/CharacterPortrait.texture = portrait_texture
	
	show_dialogue()
	display_current_line()


# Method 3: Using dictionary (good for JSON or simple data)
func start_dialogue_from_dict(dialogue_dict: Dictionary):
	start_dialogue(
		dialogue_dict.get("character_name", "Unknown"),
		dialogue_dict.get("portrait", null),
		dialogue_dict.get("lines", [])
	)

func display_current_line():
	if current_dialogue_index < dialogue_output.size():
		$DialogueBox/DialogueText.text = dialogue_output[current_dialogue_index]

func _on_continue_pressed():
	current_dialogue_index += 1
	if current_dialogue_index < dialogue_output.size():
		display_current_line()
	else:
		end_dialogue()

func show_dialogue():
	visible = true
#
func hide_dialogue():
	visible = false
#
func end_dialogue():
	hide_dialogue()
#	dialogue_finished.emit()  # Emit signal when dialogue ends
