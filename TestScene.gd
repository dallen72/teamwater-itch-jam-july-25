# TestScene.gd
extends Node2D

# Since DialogueSystem01 is already a child node, reference it directly
@onready var dialogue_system = $DialogueSystem01

func _ready():
	# Add a simple way to test - press Space to start dialogue
	pass

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space bar or Enter
		call_dialog_system()

func call_dialog_system():
	# Method 1: Using individual parameters as you wanted
	var character_name = "Test Hero"
	var portrait_texture = null  # Add your texture here: preload("res://path/to/portrait.png")
	var dialogue_lines = [
		"Hello! This is the first test line.",
		"Here's a second line of dialogue.",
		"And this is the third line.",
		"Final line - dialogue should end after this."
	]
	
	dialogue_system.start_dialogue(character_name, portrait_texture, dialogue_lines)
