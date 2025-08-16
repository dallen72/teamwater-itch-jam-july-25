extends Control

func init_hud():
	if (Global.level_num == 1): 
		# show tutorial instructions
		show_dialogue()
	Global.dialogue_finished.connect(hide_dialogue)
	
	update_energy_display(PlayerEnergy.player_energy)
	Global.energy_changed.connect(update_energy_display)

func _ready():
	# Wait for the first frame to ensure size is available
	await get_tree().process_frame
	# Register this UI area with the global click handler
	Global.register_ui_area(self, size)

func show_dialogue():
	$DialogueBox.show()
	# Load tutorial dialogue from JSON file
	$DialogueBox.load_dialogue_from_json("res://Dialogue/tutorial_dialogue.json")

func hide_dialogue():
	$DialogueBox.hide()
	
func update_energy_display(_energy_level):
	$EnergyBox/RichTextLabel.text = str(_energy_level)	
