
extends Node2D


# Export the level number so it can be set in the editor
@export var level_number: int = 1

# Export the starting energy for this level
@export var starting_energy: int = 400

func _ready():
	# Enable input processing for this node
	set_process_input(true)
	print("Level _ready() called - input processing enabled for level ", level_number)
	
	# Set global level number for other systems to use (keeping for backward compatibility)
	Global.level_num = level_number
	
	# Set starting energy for current level
	PlayerEnergy.player_energy = starting_energy
	Global.energy_changed.emit(starting_energy)
	
	# Initialize UI
	init_ui()
	
	# Show tutorial dialogue for level 1
	if level_number == 1:
		await get_tree().process_frame
		var ui = get_node_or_null("UI")
		if ui:
			ui.show_dialogue()

func init_ui():
	# Initialize HUD if UI node exists
	var ui = get_node_or_null("UI")
	if ui:
		ui.init_hud(level_number)

func _input(event):
	print("Level _input called with event: ", event)
	Global.handle_input(event)
