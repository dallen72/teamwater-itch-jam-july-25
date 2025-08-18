extends Control
# Signal for when dialogue ends
signal dialogue_finished

func hide_ui():
	$PortraitBox.hide()
	$helpButton.show()

func _ready():
	# Connect to the DialogueSystem's signal
	# Adjust the path to match where your DialogueSystem node is
	var dialogue_system = get_node("path/to/DialogueSystem")  # Update this path
	dialogue_system.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	hide_ui()
