extends Control

	
func _ready():
	# Wait for the first frame to ensure size is available
	await get_tree().process_frame
		
	update_energy_display(PlayerEnergy.player_energy)
	Global.energy_changed.connect(update_energy_display)
	Global.register_ui_area($EnergyBox, $EnergyBox.size)
	
	$DialogueBox.connect("hide", _on_dialogue_box_hide)
	Global.dialogue_finished.connect(hide_dialogue)


func _on_dialogue_box_hide():
	Global.unregister_ui_area($DialogueBox)


func show_dialogue():
	$DialogueBox.show()
	Global.register_ui_area($DialogueBox, $DialogueBox.size)
	
	# Load tutorial dialogue from JSON file
	$DialogueBox.load_dialogue_from_json("res://Dialogue/tutorial_dialogue.json")


func hide_dialogue():
	$DialogueBox.hide()
	Global.unregister_ui_area(self)


func update_energy_display(_energy_level):
	$EnergyBox/RichTextLabel.text = str(_energy_level)	
