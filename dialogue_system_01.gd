# DialogueSystem.gd
extends Node2D

@onready var dialogue_text = $DialogueText
@onready var character_portrait = $CharacterPortrait
@onready var character_name_label = $CharacterName

var dialogue_output = []
var current_dialogue_index = 0
var current_character = ""

# Signal for when dialogue ends
signal dialogue_finished

func _ready():
	start_dialogue(dialogue_text, character_portrait, character_name_label)
	$DialogueBox.pressed.connect(_on_continue_pressed)
	#hide_dialogue()

# Method 1: Using individual parameters (your current approach)
func start_dialogue(character_name: String, portrait_texture: Texture2D, dialogue_lines: Array):
	current_character = character_name
	dialogue_output = dialogue_lines
	current_dialogue_index = 0
	
	character_name_label.text = character_name  # Fixed the bug here
	character_portrait.texture = portrait_texture
	
	show_dialogue()
	display_current_line()

# Method 2: Using DialogueData resource
func start_dialogue_from_resource(dialogue_data: DialogueData):
	start_dialogue(
		dialogue_data.character_name,
		dialogue_data.character_portrait,
		dialogue_data.dialogue_lines
	)

# Method 3: Using dictionary (good for JSON or simple data)
func start_dialogue_from_dict(dialogue_dict: Dictionary):
	start_dialogue(
		dialogue_dict.get("character_name", "Unknown"),
		dialogue_dict.get("portrait", null),
		dialogue_dict.get("lines", [])
	)

func display_current_line():
	if current_dialogue_index < dialogue_output.size():
		dialogue_text.text = dialogue_output[current_dialogue_index]

func _on_continue_pressed():
	current_dialogue_index += 1
	if current_dialogue_index < dialogue_output.size():
		display_current_line()
	else:
		end_dialogue()

func show_dialogue():
	visible = true

func hide_dialogue():
	visible = false

func end_dialogue():
	hide_dialogue()
	dialogue_finished.emit()  # Emit signal when dialogue ends
