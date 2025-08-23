class_name DialogueUI
extends Control

# UI elements
@onready var character_name_label: Label = $CharacterName
@onready var portrait_texture_rect: TextureRect = $CharacterPortrait
@onready var dialogue_text_label: Label = $DialogueText
@onready var continue_button: Button = $ContinueButton

func _ready():
	# Connect continue button
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

# Display a dialogue entry
func display_dialogue_entry(entry: DialogueEntry):
	if character_name_label:
		character_name_label.text = entry.character_name
	
	if portrait_texture_rect and entry.portrait_texture:
		portrait_texture_rect.texture = entry.portrait_texture
		# Configure TextureRect to fit the texture properly within bounds
		portrait_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	if dialogue_text_label:
		dialogue_text_label.text = entry.dialogue_text

# Handle continue button press
func _on_continue_pressed():	
	get_parent().next_line_if_tutorial_done()
